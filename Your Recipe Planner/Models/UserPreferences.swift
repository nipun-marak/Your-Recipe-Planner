import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID
    var dietaryRestrictions: [DietaryRestriction]
    var allergies: [String]
    var cuisinePreferences: [String]
    var maxCookingTime: Int?
    var servingSize: Int
    var nutritionalGoals: NutritionalGoals?
    var lastUpdated: Date
    
    init(dietaryRestrictions: [DietaryRestriction] = [], 
         allergies: [String] = [], 
         cuisinePreferences: [String] = [], 
         maxCookingTime: Int? = nil, 
         servingSize: Int = 2, 
         nutritionalGoals: NutritionalGoals? = nil) {
        self.id = UUID()
        self.dietaryRestrictions = dietaryRestrictions
        self.allergies = allergies
        self.cuisinePreferences = cuisinePreferences
        self.maxCookingTime = maxCookingTime
        self.servingSize = servingSize
        self.nutritionalGoals = nutritionalGoals
        self.lastUpdated = Date()
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegan
    case vegetarian
    case glutenFree = "gluten-free"
    case ketogenic
    case paleo
    case pescetarian
    case whole30
    case dairyFree = "dairy-free"
}

@Model
final class NutritionalGoals {
    var caloriesPerDay: Int?
    var proteinPercentage: Int?
    var carbPercentage: Int?
    var fatPercentage: Int?
    
    init(caloriesPerDay: Int? = nil, proteinPercentage: Int? = nil, carbPercentage: Int? = nil, fatPercentage: Int? = nil) {
        self.caloriesPerDay = caloriesPerDay
        self.proteinPercentage = proteinPercentage
        self.carbPercentage = carbPercentage
        self.fatPercentage = fatPercentage
    }
} 