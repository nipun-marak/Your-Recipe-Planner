import Foundation
import Combine
import SwiftData

class MealPlanService {
    private let apiService: APIService
    private let modelContext: ModelContext
    private let recipeRepository: RecipeRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: APIService = .shared, modelContext: ModelContext, recipeRepository: RecipeRepository) {
        self.apiService = apiService
        self.modelContext = modelContext
        self.recipeRepository = recipeRepository
    }
    
    // MARK: - Create Meal Plan
    
    func createMealPlan(name: String, startDate: Date, days: Int = 7, preferences: UserPreferences) -> MealPlan {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: days - 1, to: startDate)!
        
        let mealPlan = MealPlan(name: name, startDate: startDate, endDate: endDate)
        
        // Create empty days
        var mealPlanDays: [MealPlanDay] = []
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
            let day = MealPlanDay(date: date)
            mealPlanDays.append(day)
        }
        
        mealPlan.days = mealPlanDays
        
        // Save to database
        modelContext.insert(mealPlan)
        try? modelContext.save()
        
        return mealPlan
    }
    
    // MARK: - Generate Meal Plan
    
    func generateMealPlan(mealPlan: MealPlan, preferences: UserPreferences) -> AnyPublisher<MealPlan, Error> {
        guard let days = mealPlan.days else {
            return Fail(error: NSError(domain: "MealPlanService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Meal plan has no days"]))
                .eraseToAnyPublisher()
        }
        
        // Create a subject that will emit the updated meal plan
        let mealPlanSubject = PassthroughSubject<MealPlan, Error>()
        
        // For each day, generate recipes for each meal type
        var dayPublishers = [AnyPublisher<MealPlanDay, Error>]()
        
        for day in days {
            let dayPublisher = generateMealsForDay(day: day, preferences: preferences)
            dayPublishers.append(dayPublisher)
        }
        
        // When all day publishers complete, update the meal plan
        Publishers.MergeMany(dayPublishers)
            .collect()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    mealPlanSubject.send(completion: .failure(error))
                }
            }, receiveValue: { updatedDays in
                mealPlan.days = updatedDays
                
                // Save to database
                try? self.modelContext.save()
                
                mealPlanSubject.send(mealPlan)
                mealPlanSubject.send(completion: .finished)
            })
            .store(in: &cancellables)
        
        return mealPlanSubject.eraseToAnyPublisher()
    }
    
    private func generateMealsForDay(day: MealPlanDay, preferences: UserPreferences) -> AnyPublisher<MealPlanDay, Error> {
        // Define meal types to generate
        let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]
        
        // Create meals if they don't exist
        if day.meals == nil {
            day.meals = mealTypes.map { MealPlanMeal(type: $0) }
        }
        
        // For each meal type, find an appropriate recipe
        guard let meals = day.meals else {
            return Fail(error: NSError(domain: "MealPlanService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Day has no meals"]))
                .eraseToAnyPublisher()
        }
        
        let mealPublishers = meals.map { meal -> AnyPublisher<MealPlanMeal, Error> in
            return self.findRecipeForMeal(meal: meal, preferences: preferences)
        }
        
        return Publishers.MergeMany(mealPublishers)
            .collect()
            .map { updatedMeals in
                day.meals = updatedMeals
                return day
            }
            .eraseToAnyPublisher()
    }
    
    private func findRecipeForMeal(meal: MealPlanMeal, preferences: UserPreferences) -> AnyPublisher<MealPlanMeal, Error> {
        // Convert preferences to tags
        var tags = [String]()
        
        // Add dietary restrictions
        for restriction in preferences.dietaryRestrictions {
            tags.append(restriction.rawValue)
        }
        
        // Add meal type
        switch meal.type {
        case .breakfast:
            tags.append("breakfast")
        case .lunch:
            tags.append("lunch")
        case .dinner:
            tags.append("dinner")
        case .snack:
            tags.append("snack")
        }
        
        // Add time constraint if specified
        if let maxTime = preferences.maxCookingTime {
            tags.append("maxReadyTime\(maxTime)")
        }
        
        // Get random recipe with these tags
        return recipeRepository.getRandomRecipes(number: 1, tags: tags)
            .map { recipes -> MealPlanMeal in
                if let recipe = recipes.first {
                    meal.recipe = recipe
                }
                return meal
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Manage Meal Plans
    
    func getAllMealPlans() -> [MealPlan] {
        let descriptor = FetchDescriptor<MealPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching meal plans: \(error)")
            return []
        }
    }
    
    func getMealPlan(id: UUID) -> MealPlan? {
        let descriptor = FetchDescriptor<MealPlan>(predicate: #Predicate { $0.id == id })
        
        do {
            let mealPlans = try modelContext.fetch(descriptor)
            return mealPlans.first
        } catch {
            print("Error fetching meal plan: \(error)")
            return nil
        }
    }
    
    func deleteMealPlan(_ mealPlan: MealPlan) {
        modelContext.delete(mealPlan)
        try? modelContext.save()
    }
    
    // MARK: - Meal Plan Management
    
    func updateMealPlanRecipe(meal: MealPlanMeal, newRecipe: Recipe) {
        meal.recipe = newRecipe
        try? modelContext.save()
    }
    
    // MARK: - Shopping List Generation
    
    func generateShoppingList(from mealPlan: MealPlan) -> ShoppingList {
        let shoppingList = ShoppingList(name: "Shopping List for \(mealPlan.name)", associatedMealPlan: mealPlan)
        
        // Collect all ingredients from all recipes in the meal plan
        var ingredientMap = [Int: (Ingredient, Double)]()
        
        if let days = mealPlan.days {
            for day in days {
                if let meals = day.meals {
                    for meal in meals {
                        if let recipe = meal.recipe, let ingredients = recipe.extendedIngredients {
                            for ingredient in ingredients {
                                if let existing = ingredientMap[ingredient.id] {
                                    // Ingredient already exists, update quantity
                                    let newQuantity = existing.1 + ingredient.amount
                                    ingredientMap[ingredient.id] = (existing.0, newQuantity)
                                } else {
                                    // New ingredient
                                    ingredientMap[ingredient.id] = (ingredient, ingredient.amount)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Create shopping items from ingredients
        let shoppingItems = ingredientMap.map { (_, tuple) -> ShoppingItem in
            let (ingredient, quantity) = tuple
            return ShoppingItem(ingredient: ingredient, quantity: quantity)
        }
        
        shoppingList.items = shoppingItems
        
        // Save to database
        modelContext.insert(shoppingList)
        try? modelContext.save()
        
        return shoppingList
    }
} 