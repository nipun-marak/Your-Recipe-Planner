import Foundation
import SwiftData

@Model
final class Recipe {
    var id: Int
    var title: String
    var summary: String
    var readyInMinutes: Int
    var servings: Int
    var sourceUrl: String?
    var image: String?
    var imageType: String?
    var instructions: String?
    var extendedIngredients: [Ingredient]?
    var diets: [String]?
    var dishTypes: [String]?
    var cuisines: [String]?
    var isFavorite: Bool
    var dateAdded: Date
    
    init(id: Int, title: String, summary: String, readyInMinutes: Int, servings: Int, 
         sourceUrl: String? = nil, image: String? = nil, imageType: String? = nil, 
         instructions: String? = nil, extendedIngredients: [Ingredient]? = nil, 
         diets: [String]? = nil, dishTypes: [String]? = nil, cuisines: [String]? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.readyInMinutes = readyInMinutes
        self.servings = servings
        self.sourceUrl = sourceUrl
        self.image = image
        self.imageType = imageType
        self.instructions = instructions
        self.extendedIngredients = extendedIngredients
        self.diets = diets
        self.dishTypes = dishTypes
        self.cuisines = cuisines
        self.isFavorite = false
        self.dateAdded = Date()
    }
}

// For API responses
struct RecipeResponse: Codable {
    let recipes: [APIRecipe]
}

struct APIRecipe: Codable {
    let id: Int
    let title: String
    let summary: String
    let readyInMinutes: Int
    let servings: Int
    let sourceUrl: String?
    let image: String?
    let imageType: String?
    let instructions: String?
    let extendedIngredients: [APIIngredient]?
    let diets: [String]?
    let dishTypes: [String]?
    let cuisines: [String]?
    
    func toModel() -> Recipe {
        let ingredients = extendedIngredients?.map { $0.toModel() }
        return Recipe(
            id: id,
            title: title,
            summary: summary,
            readyInMinutes: readyInMinutes,
            servings: servings,
            sourceUrl: sourceUrl,
            image: image,
            imageType: imageType,
            instructions: instructions,
            extendedIngredients: ingredients,
            diets: diets,
            dishTypes: dishTypes,
            cuisines: cuisines
        )
    }
} 