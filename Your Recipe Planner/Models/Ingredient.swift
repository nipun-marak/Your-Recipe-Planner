import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: Int
    var name: String
    var amount: Double
    var unit: String
    var original: String
    var image: String?
    
    init(id: Int, name: String, amount: Double, unit: String, original: String, image: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.original = original
        self.image = image
    }
}

// For API responses
struct APIIngredient: Codable {
    let id: Int
    let name: String
    let amount: Double
    let unit: String
    let original: String
    let image: String?
    
    func toModel() -> Ingredient {
        return Ingredient(
            id: id,
            name: name,
            amount: amount,
            unit: unit,
            original: original,
            image: image
        )
    }
} 