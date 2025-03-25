import Foundation
import Combine
import SwiftData

class RecipeRepository {
    private let apiService: APIService
    private let cacheService: CacheService
    private let modelContext: ModelContext
    
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: APIService = .shared, cacheService: CacheService = .shared, modelContext: ModelContext) {
        self.apiService = apiService
        self.cacheService = cacheService
        self.modelContext = modelContext
    }
    
    // MARK: - Search Recipes
    
    func searchRecipes(query: String, cuisine: String? = nil, diet: String? = nil, 
                      intolerances: String? = nil, maxReadyTime: Int? = nil, 
                      number: Int = 20, offset: Int = 0) -> AnyPublisher<[Recipe], Error> {
        
        // Generate cache key
        let cacheKey = "search_\(query)_\(cuisine ?? "")_\(diet ?? "")_\(intolerances ?? "")_\(maxReadyTime?.description ?? "")_\(number)_\(offset)"
        
        // Check if results are in cache
        if let cachedResults = cacheService.object(forKey: cacheKey, type: SearchResults.self) {
            let recipes = cachedResults.results.map { $0.toModel() }
            return Just(recipes)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Otherwise fetch from API
        return apiService.searchRecipes(query: query, cuisine: cuisine, diet: diet, 
                                       intolerances: intolerances, maxReadyTime: maxReadyTime, 
                                       number: number, offset: offset)
            .handleEvents(receiveOutput: { [weak self] searchResults in
                // Cache the results
                self?.cacheService.cache(object: searchResults, forKey: cacheKey, expiration: 3600) // Cache for 1 hour
            })
            .map { searchResults in
                // Convert to model objects
                return searchResults.results.map { $0.toModel() }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Recipe Detail
    
    func getRecipeDetail(id: Int) -> AnyPublisher<Recipe, Error> {
        // Check if recipe is in local database first
        if let recipe = getRecipeFromLocalDB(id: id) {
            return Just(recipe)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Check if recipe is in cache
        let cacheKey = "recipe_\(id)"
        if let cachedRecipe = cacheService.object(forKey: cacheKey, type: APIRecipe.self) {
            return Just(cachedRecipe.toModel())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Otherwise fetch from API
        return apiService.getRecipeInformation(id: id)
            .handleEvents(receiveOutput: { [weak self] apiRecipe in
                // Cache the result
                self?.cacheService.cache(object: apiRecipe, forKey: cacheKey, expiration: 86400) // Cache for 24 hours
            })
            .map { $0.toModel() }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Favorites Management
    
    func saveRecipeAsFavorite(_ recipe: Recipe) {
        recipe.isFavorite = true
        do {
            modelContext.insert(recipe)
            try modelContext.save()
        } catch {
            print("Error saving favorite recipe: \(error)")
        }
    }
    
    func removeRecipeFromFavorites(_ recipe: Recipe) {
        if let localRecipe = getRecipeFromLocalDB(id: recipe.id) {
            modelContext.delete(localRecipe)
            do {
                try modelContext.save()
            } catch {
                print("Error removing favorite recipe: \(error)")
            }
        }
    }
    
    func getFavoriteRecipes() -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { $0.isFavorite == true })
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching favorite recipes: \(error)")
            return []
        }
    }
    
    // MARK: - Random Recipes
    
    func getRandomRecipes(number: Int = 10, tags: [String]? = nil) -> AnyPublisher<[Recipe], Error> {
        return apiService.getRandomRecipes(number: number, tags: tags)
            .map { $0.recipes.map { $0.toModel() } }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func getRecipeFromLocalDB(id: Int) -> Recipe? {
        let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { $0.id == id })
        
        do {
            let recipes = try modelContext.fetch(descriptor)
            return recipes.first
        } catch {
            print("Error fetching recipe from database: \(error)")
            return nil
        }
    }
} 