import Foundation
import Combine
import SwiftData

class RecipeListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchQuery = ""
    @Published var selectedCuisine: String?
    @Published var selectedDiet: String?
    @Published var selectedIntolerances: [String] = []
    @Published var maxReadyTime: Int?
    
    // MARK: - Private Properties
    
    private let recipeRepository: RecipeRepository
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 0
    private var hasMoreResults = true
    private let resultsPerPage = 20
    
    // MARK: - Initialization
    
    init(recipeRepository: RecipeRepository) {
        self.recipeRepository = recipeRepository
    }
    
    // MARK: - Public Methods
    
    func searchRecipes() {
        guard !searchQuery.isEmpty else {
            fetchRandomRecipes()
            return
        }
        
        isLoading = true
        error = nil
        currentPage = 0
        recipes = []
        
        loadMore()
    }
    
    func loadMore() {
        guard !isLoading && hasMoreResults else { return }
        
        isLoading = true
        
        // Create intolerances string
        let intolerancesString = selectedIntolerances.isEmpty ? nil : selectedIntolerances.joined(separator: ",")
        
        recipeRepository.searchRecipes(
            query: searchQuery,
            cuisine: selectedCuisine,
            diet: selectedDiet,
            intolerances: intolerancesString,
            maxReadyTime: maxReadyTime,
            number: resultsPerPage,
            offset: currentPage * resultsPerPage
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                self?.error = "Error loading recipes: \(error.localizedDescription)"
            }
        } receiveValue: { [weak self] newRecipes in
            guard let self = self else { return }
            
            if newRecipes.isEmpty {
                self.hasMoreResults = false
            } else {
                self.recipes.append(contentsOf: newRecipes)
                self.currentPage += 1
            }
        }
        .store(in: &cancellables)
    }
    
    func resetFilters() {
        selectedCuisine = nil
        selectedDiet = nil
        selectedIntolerances = []
        maxReadyTime = nil
    }
    
    // MARK: - Random Recipes
    
    func fetchRandomRecipes() {
        isLoading = true
        error = nil
        
        var tags: [String] = []
        
        if let diet = selectedDiet {
            tags.append(diet)
        }
        
        recipeRepository.getRandomRecipes(number: 20, tags: tags.isEmpty ? nil : tags)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = "Error loading random recipes: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] randomRecipes in
                self?.recipes = randomRecipes
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Favorite Management
    
    func toggleFavorite(_ recipe: Recipe) {
        if recipe.isFavorite {
            recipeRepository.removeRecipeFromFavorites(recipe)
            
            // Update the recipe in the current list
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index].isFavorite = false
            }
        } else {
            recipeRepository.saveRecipeAsFavorite(recipe)
            
            // Update the recipe in the current list
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index].isFavorite = true
            }
        }
    }
    
    // MARK: - Diet Options
    
    func getDietOptions() -> [String] {
        return ["vegetarian", "vegan", "gluten-free", "ketogenic", "paleo", "pescetarian", "whole30"]
    }
    
    // MARK: - Intolerance Options
    
    func getIntoleranceOptions() -> [String] {
        return ["dairy", "egg", "gluten", "grain", "peanut", "seafood", "sesame", "shellfish", "soy", "sulfite", "tree nut", "wheat"]
    }
} 