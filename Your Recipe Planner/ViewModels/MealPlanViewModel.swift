import Foundation
import Combine
import SwiftData

class MealPlanViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var mealPlans: [MealPlan] = []
    @Published var currentMealPlan: MealPlan?
    @Published var isLoading = false
    @Published var error: String?
    @Published var planName = ""
    @Published var startDate = Date()
    @Published var numberOfDays = 7
    
    // MARK: - Private Properties
    
    private let mealPlanService: MealPlanService
    private let userPreferencesService: UserPreferencesService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(mealPlanService: MealPlanService, userPreferencesService: UserPreferencesService) {
        self.mealPlanService = mealPlanService
        self.userPreferencesService = userPreferencesService
        
        loadMealPlans()
    }
    
    // MARK: - Public Methods
    
    func loadMealPlans() {
        mealPlans = mealPlanService.getAllMealPlans()
    }
    
    func createMealPlan() {
        guard !planName.isEmpty else {
            error = "Please enter a name for your meal plan"
            return
        }
        
        let preferences = userPreferencesService.getUserPreferences()
        let newMealPlan = mealPlanService.createMealPlan(
            name: planName,
            startDate: startDate,
            days: numberOfDays,
            preferences: preferences
        )
        
        mealPlans.insert(newMealPlan, at: 0)
        currentMealPlan = newMealPlan
        resetForm()
    }
    
    func deleteMealPlan(_ mealPlan: MealPlan) {
        mealPlanService.deleteMealPlan(mealPlan)
        
        if currentMealPlan?.id == mealPlan.id {
            currentMealPlan = nil
        }
        
        loadMealPlans()
    }
    
    func selectMealPlan(_ mealPlan: MealPlan) {
        currentMealPlan = mealPlan
    }
    
    func generateMealPlan() {
        guard let mealPlan = currentMealPlan else {
            error = "No meal plan selected"
            return
        }
        
        isLoading = true
        error = nil
        
        let preferences = userPreferencesService.getUserPreferences()
        
        mealPlanService.generateMealPlan(mealPlan: mealPlan, preferences: preferences)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = "Error generating meal plan: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] updatedMealPlan in
                self?.currentMealPlan = updatedMealPlan
                self?.loadMealPlans()
            }
            .store(in: &cancellables)
    }
    
    func updateMealRecipe(meal: MealPlanMeal, recipe: Recipe) {
        mealPlanService.updateMealPlanRecipe(meal: meal, newRecipe: recipe)
    }
    
    func generateShoppingList() -> ShoppingList? {
        guard let mealPlan = currentMealPlan else {
            error = "No meal plan selected"
            return nil
        }
        
        return mealPlanService.generateShoppingList(from: mealPlan)
    }
    
    // MARK: - Formatting Helpers
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatMealPlanDateRange(_ mealPlan: MealPlan) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return "\(formatter.string(from: mealPlan.startDate)) - \(formatter.string(from: mealPlan.endDate))"
    }
    
    // MARK: - Private Methods
    
    private func resetForm() {
        planName = ""
        startDate = Date()
        numberOfDays = 7
    }
} 