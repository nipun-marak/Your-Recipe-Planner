import Foundation
import Combine
import SwiftData
import UIKit

class ShoppingListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var shoppingLists: [ShoppingList] = []
    @Published var currentShoppingList: ShoppingList?
    @Published var newListName = ""
    @Published var error: String?
    
    // MARK: - Private Properties
    
    private let shoppingListService: ShoppingListService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(shoppingListService: ShoppingListService) {
        self.shoppingListService = shoppingListService
        
        loadShoppingLists()
    }
    
    // MARK: - Public Methods
    
    func loadShoppingLists() {
        shoppingLists = shoppingListService.getAllShoppingLists()
    }
    
    func createShoppingList() {
        guard !newListName.isEmpty else {
            error = "Please enter a name for your shopping list"
            return
        }
        
        let newList = shoppingListService.createShoppingList(name: newListName)
        shoppingLists.insert(newList, at: 0)
        currentShoppingList = newList
        
        newListName = ""
    }
    
    func deleteShoppingList(_ shoppingList: ShoppingList) {
        shoppingListService.deleteShoppingList(shoppingList)
        
        if currentShoppingList?.id == shoppingList.id {
            currentShoppingList = nil
        }
        
        loadShoppingLists()
    }
    
    func selectShoppingList(_ shoppingList: ShoppingList) {
        currentShoppingList = shoppingList
    }
    
    // MARK: - Shopping Item Management
    
    func toggleItemCompletion(_ item: ShoppingItem) {
        shoppingListService.toggleItemCompletion(item: item)
    }
    
    func updateItemQuantity(_ item: ShoppingItem, newQuantity: Double) {
        shoppingListService.updateItemQuantity(item: item, newQuantity: newQuantity)
    }
    
    func addItemToList(ingredient: Ingredient, quantity: Double, notes: String? = nil) {
        guard let shoppingList = currentShoppingList else {
            error = "No shopping list selected"
            return
        }
        
        shoppingListService.addItemToShoppingList(
            shoppingList: shoppingList,
            ingredient: ingredient,
            quantity: quantity,
            notes: notes
        )
    }
    
    func removeItemFromList(_ item: ShoppingItem) {
        guard let shoppingList = currentShoppingList else {
            error = "No shopping list selected"
            return
        }
        
        shoppingListService.removeItemFromShoppingList(shoppingList: shoppingList, item: item)
    }
    
    // MARK: - Sharing
    
    func shareShoppingList() -> URL? {
        guard let shoppingList = currentShoppingList else {
            error = "No shopping list selected"
            return nil
        }
        
        return shoppingListService.generateShoppingListURL(shoppingList)
    }
    
    func getTextRepresentation() -> String {
        guard let shoppingList = currentShoppingList else {
            return ""
        }
        
        return shoppingListService.exportShoppingListAsText(shoppingList)
    }
    
    // MARK: - Helpers
    
    func getCompletedItemCount() -> Int {
        guard let items = currentShoppingList?.items else {
            return 0
        }
        
        return items.filter { $0.isCompleted }.count
    }
    
    func getTotalItemCount() -> Int {
        return currentShoppingList?.items?.count ?? 0
    }
    
    func getCompletionPercentage() -> Double {
        let totalCount = getTotalItemCount()
        guard totalCount > 0 else { return 0 }
        
        let completedCount = getCompletedItemCount()
        return Double(completedCount) / Double(totalCount)
    }
} 