import Foundation
import Combine

class UserPreferencesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var userPreferences: UserPreferences?
    @Published var selectedDietaryRestrictions: [DietaryRestriction] = []
    @Published var selectedAllergies: [String] = []
    @Published var selectedCuisines: [String] = []
    @Published var maxCookingTime: Int?
    @Published var servingSize: Int = 2
    @Published var caloriesPerDay: Int?
    @Published var proteinPercentage: Int?
    @Published var carbPercentage: Int?
    @Published var fatPercentage: Int?
    
    // MARK: - Private Properties
    
    private let userPreferencesService: UserPreferencesService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(userPreferencesService: UserPreferencesService) {
        self.userPreferencesService = userPreferencesService
        
        loadPreferences()
    }
    
    // MARK: - Public Methods
    
    func loadPreferences() {
        let preferences = userPreferencesService.getUserPreferences()
        userPreferences = preferences
        
        // Sync published properties with stored preferences
        selectedDietaryRestrictions = preferences.dietaryRestrictions
        selectedAllergies = preferences.allergies
        selectedCuisines = preferences.cuisinePreferences
        maxCookingTime = preferences.maxCookingTime
        servingSize = preferences.servingSize
        
        if let nutritionalGoals = preferences.nutritionalGoals {
            caloriesPerDay = nutritionalGoals.caloriesPerDay
            proteinPercentage = nutritionalGoals.proteinPercentage
            carbPercentage = nutritionalGoals.carbPercentage
            fatPercentage = nutritionalGoals.fatPercentage
        }
    }
    
    func savePreferences() {
        let nutritionalGoals = NutritionalGoals(
            caloriesPerDay: caloriesPerDay,
            proteinPercentage: proteinPercentage,
            carbPercentage: carbPercentage,
            fatPercentage: fatPercentage
        )
        
        userPreferencesService.updateUserPreferences(
            dietaryRestrictions: selectedDietaryRestrictions,
            allergies: selectedAllergies,
            cuisinePreferences: selectedCuisines,
            maxCookingTime: maxCookingTime,
            servingSize: servingSize,
            nutritionalGoals: nutritionalGoals
        )
        
        loadPreferences()
    }
    
    func resetPreferences() {
        selectedDietaryRestrictions = []
        selectedAllergies = []
        selectedCuisines = []
        maxCookingTime = nil
        servingSize = 2
        caloriesPerDay = nil
        proteinPercentage = nil
        carbPercentage = nil
        fatPercentage = nil
        
        savePreferences()
    }
    
    // MARK: - Option Lists
    
    func getAllDietaryRestrictions() -> [DietaryRestriction] {
        return userPreferencesService.getAllDietaryRestrictions()
    }
    
    func getCommonAllergies() -> [String] {
        return userPreferencesService.getCommonAllergies()
    }
    
    func getCommonCuisines() -> [String] {
        return userPreferencesService.getCommonCuisines()
    }
    
    func getCookingTimeOptions() -> [Int?] {
        return [nil, 15, 30, 45, 60, 90, 120]
    }
    
    func getServingSizeOptions() -> [Int] {
        return Array(1...10)
    }
    
    // MARK: - Validation
    
    func validateNutritionalGoals() -> Bool {
        // Check if percentages add up to 100
        if let protein = proteinPercentage, let carbs = carbPercentage, let fat = fatPercentage {
            let sum = protein + carbs + fat
            return sum == 100
        }
        
        // If any are nil, it's valid (not setting complete macros)
        return true
    }
    
    func formatCookingTime(_ time: Int?) -> String {
        guard let time = time else {
            return "Any"
        }
        
        return "\(time) min"
    }
} 