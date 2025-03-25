import Foundation
import Combine

class RecipeDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var recipe: Recipe?
    @Published var isLoading = false
    @Published var error: String?
    @Published var servings: Int
    
    // MARK: - Private Properties
    
    private let recipeRepository: RecipeRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(recipeRepository: RecipeRepository, recipe: Recipe? = nil) {
        self.recipeRepository = recipeRepository
        self.recipe = recipe
        self.servings = recipe?.servings ?? 2
    }
    
    // MARK: - Public Methods
    
    func loadRecipeDetails(id: Int) {
        // If recipe already loaded with full details, no need to reload
        if let existingRecipe = recipe, existingRecipe.id == id, existingRecipe.instructions != nil {
            return
        }
        
        isLoading = true
        error = nil
        
        recipeRepository.getRecipeDetail(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = "Error loading recipe details: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] recipe in
                self?.recipe = recipe
                self?.servings = recipe.servings
            }
            .store(in: &cancellables)
    }
    
    func toggleFavorite() {
        guard let recipe = recipe else { return }
        
        if recipe.isFavorite {
            recipeRepository.removeRecipeFromFavorites(recipe)
            self.recipe?.isFavorite = false
        } else {
            recipeRepository.saveRecipeAsFavorite(recipe)
            self.recipe?.isFavorite = true
        }
    }
    
    // MARK: - Ingredient Calculation
    
    func getAdjustedIngredients() -> [Ingredient] {
        guard let recipe = recipe, let ingredients = recipe.extendedIngredients else {
            return []
        }
        
        // If servings match the recipe, return original ingredients
        if servings == recipe.servings {
            return ingredients
        }
        
        // Otherwise adjust quantities
        let ratio = Double(servings) / Double(recipe.servings)
        
        return ingredients.map { ingredient in
            // Create a copy with adjusted amount
            let adjustedIngredient = Ingredient(
                id: ingredient.id,
                name: ingredient.name,
                amount: ingredient.amount * ratio,
                unit: ingredient.unit,
                original: ingredient.original,
                image: ingredient.image
            )
            return adjustedIngredient
        }
    }
    
    // MARK: - Nutritional Information
    
    func getNutritionalInfo() -> [String: String] {
        // This would typically come from the API, but for now we'll return placeholder data
        return [
            "Calories": "250 kcal",
            "Protein": "15g",
            "Carbs": "30g",
            "Fat": "10g"
        ]
    }
    
    // MARK: - Cooking Times
    
    func getCookingTimes() -> [String: Int] {
        guard let recipe = recipe else { return [:] }
        
        // Example calculation - in a real app, this would come from the API
        let prepTime = max(5, recipe.readyInMinutes / 3)
        let cookTime = max(10, recipe.readyInMinutes - prepTime)
        
        return [
            "Preparation": prepTime,
            "Cooking": cookTime,
            "Total": recipe.readyInMinutes
        ]
    }
} 