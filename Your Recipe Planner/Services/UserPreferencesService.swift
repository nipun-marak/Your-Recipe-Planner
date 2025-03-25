import Foundation
import SwiftData

class UserPreferencesService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Manage User Preferences
    
    func getUserPreferences() -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            if let existingPreferences = preferences.first {
                return existingPreferences
            } else {
                // Create default preferences if none exist
                return createDefaultPreferences()
            }
        } catch {
            print("Error fetching user preferences: \(error)")
            return createDefaultPreferences()
        }
    }
    
    func updateUserPreferences(dietaryRestrictions: [DietaryRestriction]? = nil,
                               allergies: [String]? = nil,
                               cuisinePreferences: [String]? = nil,
                               maxCookingTime: Int? = nil,
                               servingSize: Int? = nil,
                               nutritionalGoals: NutritionalGoals? = nil) -> UserPreferences {
        
        let preferences = getUserPreferences()
        
        if let dietaryRestrictions = dietaryRestrictions {
            preferences.dietaryRestrictions = dietaryRestrictions
        }
        
        if let allergies = allergies {
            preferences.allergies = allergies
        }
        
        if let cuisinePreferences = cuisinePreferences {
            preferences.cuisinePreferences = cuisinePreferences
        }
        
        if let maxCookingTime = maxCookingTime {
            preferences.maxCookingTime = maxCookingTime
        }
        
        if let servingSize = servingSize {
            preferences.servingSize = servingSize
        }
        
        if let nutritionalGoals = nutritionalGoals {
            preferences.nutritionalGoals = nutritionalGoals
        }
        
        preferences.lastUpdated = Date()
        
        try? modelContext.save()
        
        return preferences
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultPreferences() -> UserPreferences {
        let preferences = UserPreferences()
        
        modelContext.insert(preferences)
        try? modelContext.save()
        
        return preferences
    }
    
    // MARK: - Dietary Restrictions
    
    func getAllDietaryRestrictions() -> [DietaryRestriction] {
        return DietaryRestriction.allCases
    }
    
    // MARK: - Common Cuisines
    
    func getCommonCuisines() -> [String] {
        return [
            "African",
            "American",
            "British",
            "Cajun",
            "Caribbean",
            "Chinese",
            "Eastern European",
            "European",
            "French",
            "German",
            "Greek",
            "Indian",
            "Irish",
            "Italian",
            "Japanese",
            "Jewish",
            "Korean",
            "Latin American",
            "Mediterranean",
            "Mexican",
            "Middle Eastern",
            "Nordic",
            "Southern",
            "Spanish",
            "Thai",
            "Vietnamese"
        ]
    }
    
    // MARK: - Common Allergies
    
    func getCommonAllergies() -> [String] {
        return [
            "Dairy",
            "Egg",
            "Gluten",
            "Grain",
            "Peanut",
            "Seafood",
            "Sesame",
            "Shellfish",
            "Soy",
            "Sulfite",
            "Tree Nut",
            "Wheat"
        ]
    }
} 