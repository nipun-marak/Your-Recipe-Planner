import Foundation
import Combine
import SwiftData

class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var favoriteRecipes: [Recipe] = []
    @Published var filteredRecipes: [Recipe] = []
    @Published var searchText = ""
    @Published var selectedCategory: String?
    
    // MARK: - Private Properties
    
    private let recipeRepository: RecipeRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(recipeRepository: RecipeRepository) {
        self.recipeRepository = recipeRepository
        
        // Set up search and filtering
        setupBindings()
        
        // Load favorites immediately
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    func loadFavorites() {
        favoriteRecipes = recipeRepository.getFavoriteRecipes()
        applyFilters()
    }
    
    func removeFromFavorites(_ recipe: Recipe) {
        recipeRepository.removeRecipeFromFavorites(recipe)
        loadFavorites()
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Categories
    
    func getCategories() -> [String] {
        // Extract categories from favorite recipes
        var categories = Set<String>()
        
        for recipe in favoriteRecipes {
            if let cuisines = recipe.cuisines {
                categories.formUnion(cuisines)
            }
            
            if let dishTypes = recipe.dishTypes {
                categories.formUnion(dishTypes)
            }
            
            if let diets = recipe.diets {
                categories.formUnion(diets)
            }
        }
        
        return Array(categories).sorted()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Update filtered recipes whenever search text or category changes
        Publishers.CombineLatest($searchText, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        filteredRecipes = favoriteRecipes.filter { recipe in
            var matchesSearch = true
            var matchesCategory = true
            
            // Apply search filter
            if !searchText.isEmpty {
                matchesSearch = recipe.title.lowercased().contains(searchText.lowercased())
            }
            
            // Apply category filter
            if let category = selectedCategory, !category.isEmpty {
                matchesCategory = (recipe.cuisines?.contains(category) == true) ||
                                 (recipe.dishTypes?.contains(category) == true) ||
                                 (recipe.diets?.contains(category) == true)
            }
            
            return matchesSearch && matchesCategory
        }
    }
} 