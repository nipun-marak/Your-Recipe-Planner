import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var viewModel: UserPreferencesViewModel
    @State private var showNutritionalWarning = false
    
    var body: some View {
        NavigationView {
            Form {
                // Dietary Restrictions
                Section(header: Text("Dietary Restrictions")) {
                    ForEach(viewModel.getAllDietaryRestrictions(), id: \.self) { restriction in
                        Toggle(restriction.rawValue.capitalized, isOn: Binding(
                            get: { viewModel.selectedDietaryRestrictions.contains(restriction) },
                            set: { isSelected in
                                if isSelected {
                                    viewModel.selectedDietaryRestrictions.append(restriction)
                                } else {
                                    viewModel.selectedDietaryRestrictions.removeAll { $0 == restriction }
                                }
                            }
                        ))
                    }
                }
                
                // Allergies
                Section(header: Text("Allergies")) {
                    NavigationLink(destination: AllergySelectionView(viewModel: viewModel)) {
                        HStack {
                            Text("Manage Allergies")
                            Spacer()
                            Text("\(viewModel.selectedAllergies.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Cuisine Preferences
                Section(header: Text("Cuisine Preferences")) {
                    NavigationLink(destination: CuisineSelectionView(viewModel: viewModel)) {
                        HStack {
                            Text("Preferred Cuisines")
                            Spacer()
                            Text("\(viewModel.selectedCuisines.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Cooking Preferences
                Section(header: Text("Cooking Preferences")) {
                    Picker("Maximum Cooking Time", selection: $viewModel.maxCookingTime) {
                        Text("Any").tag(nil as Int?)
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { time in
                            Text("\(time) minutes").tag(time as Int?)
                        }
                    }
                    
                    Stepper("Default Servings: \(viewModel.servingSize)", value: $viewModel.servingSize, in: 1...10)
                }
                
                // Nutritional Goals
                Section(header: Text("Nutritional Goals")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Daily Calories")
                            Spacer()
                            TextField("Calories", value: $viewModel.caloriesPerDay, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        Divider()
                        
                        Text("Macronutrient Ratio")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack {
                                Text("Protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Protein %", value: $viewModel.proteinPercentage, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            Text("+")
                                .foregroundColor(.secondary)
                            
                            VStack {
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Carbs %", value: $viewModel.carbPercentage, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            Text("+")
                                .foregroundColor(.secondary)
                            
                            VStack {
                                Text("Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Fat %", value: $viewModel.fatPercentage, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            Text("= 100%")
                                .foregroundColor(.secondary)
                        }
                        
                        if !viewModel.validateNutritionalGoals() {
                            Text("Total percentages should equal 100%")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Save and Reset Buttons
                Section {
                    HStack {
                        Button(action: {
                            if viewModel.validateNutritionalGoals() {
                                viewModel.savePreferences()
                            } else {
                                showNutritionalWarning = true
                            }
                        }) {
                            Text("Save Preferences")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(role: .destructive, action: {
                            viewModel.resetPreferences()
                        }) {
                            Text("Reset")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Recipe Data Provided By")
                        Spacer()
                        Text("Spoonacular API")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://spoonacular.com/food-api")!) {
                        Text("Visit Spoonacular")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Invalid Nutritional Settings", isPresented: $showNutritionalWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Protein, carbs, and fat percentages should add up to 100%. Please adjust your values.")
            }
            .onAppear {
                viewModel.loadPreferences()
            }
        }
    }
}

struct AllergySelectionView: View {
    @ObservedObject var viewModel: UserPreferencesViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredAllergies: [String] {
        if searchText.isEmpty {
            return viewModel.getCommonAllergies()
        } else {
            return viewModel.getCommonAllergies().filter {
                $0.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(filteredAllergies, id: \.self) { allergy in
                    Button(action: {
                        toggleAllergy(allergy)
                    }) {
                        HStack {
                            Text(allergy)
                            Spacer()
                            if viewModel.selectedAllergies.contains(allergy) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search allergies")
        .navigationTitle("Allergies")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
    
    private func toggleAllergy(_ allergy: String) {
        if viewModel.selectedAllergies.contains(allergy) {
            viewModel.selectedAllergies.removeAll { $0 == allergy }
        } else {
            viewModel.selectedAllergies.append(allergy)
        }
    }
}

struct CuisineSelectionView: View {
    @ObservedObject var viewModel: UserPreferencesViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredCuisines: [String] {
        if searchText.isEmpty {
            return viewModel.getCommonCuisines()
        } else {
            return viewModel.getCommonCuisines().filter {
                $0.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(filteredCuisines, id: \.self) { cuisine in
                    Button(action: {
                        toggleCuisine(cuisine)
                    }) {
                        HStack {
                            Text(cuisine)
                            Spacer()
                            if viewModel.selectedCuisines.contains(cuisine) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search cuisines")
        .navigationTitle("Preferred Cuisines")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
    
    private func toggleCuisine(_ cuisine: String) {
        if viewModel.selectedCuisines.contains(cuisine) {
            viewModel.selectedCuisines.removeAll { $0 == cuisine }
        } else {
            viewModel.selectedCuisines.append(cuisine)
        }
    }
}

#Preview {
    // Configure an in-memory container for previews
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserPreferences.self,  // Add all related models here
        configurations: config
    )
    
    return SettingsView()
        .environmentObject(UserPreferencesViewModel(
            userPreferencesService: UserPreferencesService(
                modelContext: ModelContext(container)
            )
        ))
}
