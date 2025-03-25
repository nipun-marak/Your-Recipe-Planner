import Foundation
import SwiftData

@Model
final class ShoppingList {
    var id: UUID
    var name: String
    var items: [ShoppingItem]?
    var createdAt: Date
    var associatedMealPlan: MealPlan?
    
    init(name: String, items: [ShoppingItem]? = nil, associatedMealPlan: MealPlan? = nil) {
        self.id = UUID()
        self.name = name
        self.items = items
        self.createdAt = Date()
        self.associatedMealPlan = associatedMealPlan
    }
}

@Model
final class ShoppingItem {
    var id: UUID
    var ingredient: Ingredient
    var quantity: Double
    var isCompleted: Bool
    var notes: String?
    
    init(ingredient: Ingredient, quantity: Double, isCompleted: Bool = false, notes: String? = nil) {
        self.id = UUID()
        self.ingredient = ingredient
        self.quantity = quantity
        self.isCompleted = isCompleted
        self.notes = notes
    }
} 
