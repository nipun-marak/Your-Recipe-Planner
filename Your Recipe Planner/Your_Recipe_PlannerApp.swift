import SwiftUI
import SwiftData

@main
struct Your_Recipe_PlannerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
            MealPlan.self,
            MealPlanDay.self,
            MealPlanMeal.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserPreferences.self,
            NutritionalGoals.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppCoordinator: ObservableObject {
    let modelContext: ModelContext
    
    // Services
    let recipeRepository: RecipeRepository
    let mealPlanService: MealPlanService
    let userPreferencesService: UserPreferencesService
    let shoppingListService: ShoppingListService
    
    // ViewModels
    @Published var recipeListViewModel: RecipeListViewModel
    @Published var favoritesViewModel: FavoritesViewModel
    @Published var mealPlanViewModel: MealPlanViewModel
    @Published var shoppingListViewModel: ShoppingListViewModel
    @Published var userPreferencesViewModel: UserPreferencesViewModel
    
    init() {
        // Set up ModelContext
        let descriptor = ModelConfiguration(isStoredInMemoryOnly: false)
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
            MealPlan.self,
            MealPlanDay.self,
            MealPlanMeal.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserPreferences.self,
            NutritionalGoals.self
        ])
        
        do {
            let container = try ModelContainer(for: schema, configurations: [descriptor])
            modelContext = ModelContext(container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Initialize services
        recipeRepository = RecipeRepository(modelContext: modelContext)
        userPreferencesService = UserPreferencesService(modelContext: modelContext)
        mealPlanService = MealPlanService(modelContext: modelContext, recipeRepository: recipeRepository)
        shoppingListService = ShoppingListService(modelContext: modelContext)
        
        // Initialize view models
        recipeListViewModel = RecipeListViewModel(recipeRepository: recipeRepository)
        favoritesViewModel = FavoritesViewModel(recipeRepository: recipeRepository)
        mealPlanViewModel = MealPlanViewModel(mealPlanService: mealPlanService, userPreferencesService: userPreferencesService)
        shoppingListViewModel = ShoppingListViewModel(shoppingListService: shoppingListService)
        userPreferencesViewModel = UserPreferencesViewModel(userPreferencesService: userPreferencesService)
    }
    
    func createRecipeDetailViewModel(for recipe: Recipe) -> RecipeDetailViewModel {
        return RecipeDetailViewModel(recipeRepository: recipeRepository, recipe: recipe)
    }
}
