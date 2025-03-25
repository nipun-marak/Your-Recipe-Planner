import Foundation
import SwiftData

class ShoppingListService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Manage Shopping Lists
    
    func getAllShoppingLists() -> [ShoppingList] {
        let descriptor = FetchDescriptor<ShoppingList>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching shopping lists: \(error)")
            return []
        }
    }
    
    func getShoppingList(id: UUID) -> ShoppingList? {
        let descriptor = FetchDescriptor<ShoppingList>(predicate: #Predicate { $0.id == id })
        
        do {
            let shoppingLists = try modelContext.fetch(descriptor)
            return shoppingLists.first
        } catch {
            print("Error fetching shopping list: \(error)")
            return nil
        }
    }
    
    func createShoppingList(name: String) -> ShoppingList {
        let shoppingList = ShoppingList(name: name)
        
        modelContext.insert(shoppingList)
        try? modelContext.save()
        
        return shoppingList
    }
    
    func deleteShoppingList(_ shoppingList: ShoppingList) {
        modelContext.delete(shoppingList)
        try? modelContext.save()
    }
    
    // MARK: - Manage Shopping Items
    
    func addItemToShoppingList(shoppingList: ShoppingList, ingredient: Ingredient, quantity: Double, notes: String? = nil) {
        let item = ShoppingItem(ingredient: ingredient, quantity: quantity, notes: notes)
        
        if shoppingList.items == nil {
            shoppingList.items = []
        }
        
        shoppingList.items?.append(item)
        
        try? modelContext.save()
    }
    
    func removeItemFromShoppingList(shoppingList: ShoppingList, item: ShoppingItem) {
        guard let items = shoppingList.items, let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        shoppingList.items?.remove(at: index)
        modelContext.delete(item)
        
        try? modelContext.save()
    }
    
    func toggleItemCompletion(item: ShoppingItem) {
        item.isCompleted.toggle()
        try? modelContext.save()
    }
    
    func updateItemQuantity(item: ShoppingItem, newQuantity: Double) {
        item.quantity = newQuantity
        try? modelContext.save()
    }
    
    func updateItemNotes(item: ShoppingItem, notes: String?) {
        item.notes = notes
        try? modelContext.save()
    }
    
    // MARK: - Export Shopping List
    
    func exportShoppingListAsText(_ shoppingList: ShoppingList) -> String {
        var text = "\(shoppingList.name)\n\n"
        
        // Group items by category or something similar
        let sortedItems = shoppingList.items?.sorted { $0.ingredient.name < $1.ingredient.name } ?? []
        
        for item in sortedItems {
            let checkmark = item.isCompleted ? "☑ " : "☐ "
            let quantityText = "\(item.quantity) \(item.ingredient.unit)"
            text += "\(checkmark)\(item.ingredient.name) - \(quantityText)\n"
            
            if let notes = item.notes, !notes.isEmpty {
                text += "   Note: \(notes)\n"
            }
        }
        
        return text
    }
    
    // MARK: - Share Shopping List
    
    func generateShoppingListURL(_ shoppingList: ShoppingList) -> URL? {
        let text = exportShoppingListAsText(shoppingList)
        
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("\(shoppingList.name).txt")
            
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error generating shopping list file: \(error)")
            return nil
        }
    }
} 