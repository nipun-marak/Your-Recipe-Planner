import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    
    var body: some View {
        TabView {
            RecipeListView()
                .environmentObject(appCoordinator.recipeListViewModel)
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
            
            FavoritesView()
                .environmentObject(appCoordinator.favoritesViewModel)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            
            MealPlanView()
                .environmentObject(appCoordinator.mealPlanViewModel)
                .tabItem {
                    Label("Meal Plans", systemImage: "calendar")
                }
            
            ShoppingListView()
                .environmentObject(appCoordinator.shoppingListViewModel)
                .tabItem {
                    Label("Shopping", systemImage: "cart.fill")
                }
            
            SettingsView()
                .environmentObject(appCoordinator.userPreferencesViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self], inMemory: true)
        .environmentObject(AppCoordinator())
}
