import Foundation
import SwiftData

@Model
final class MealPlan {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var days: [MealPlanDay]?
    var createdAt: Date
    
    init(name: String, startDate: Date, endDate: Date, days: [MealPlanDay]? = nil) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.days = days
        self.createdAt = Date()
    }
}

@Model
final class MealPlanDay {
    var id: UUID
    var date: Date
    var meals: [MealPlanMeal]?
    
    init(date: Date, meals: [MealPlanMeal]? = nil) {
        self.id = UUID()
        self.date = date
        self.meals = meals
    }
}

@Model
final class MealPlanMeal {
    var id: UUID
    var type: MealType
    var recipe: Recipe?
    
    init(type: MealType, recipe: Recipe? = nil) {
        self.id = UUID()
        self.type = type
        self.recipe = recipe
    }
}

enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
    case snack
} 