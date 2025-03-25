import SwiftUI
import SwiftData

struct MealPlanView: View {
    @EnvironmentObject var viewModel: MealPlanViewModel
    @State private var showingNewPlanSheet = false
    @State private var showingGenerateAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.mealPlans.isEmpty {
                    emptyStateView
                } else {
                    VStack {
                        // Meal plan selection
                        selectorView
                        
                        // Meal plan details
                        if let currentPlan = viewModel.currentMealPlan {
                            mealPlanDetailView(for: currentPlan)
                        } else {
                            Text("Select a meal plan to view details")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("Meal Plans")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingNewPlanSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewPlanSheet) {
                NewMealPlanView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadMealPlans()
                if viewModel.currentMealPlan == nil && !viewModel.mealPlans.isEmpty {
                    viewModel.selectMealPlan(viewModel.mealPlans[0])
                }
            }
            .alert("Generate Meal Plan", isPresented: $showingGenerateAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Generate") {
                    viewModel.generateMealPlan()
                }
            } message: {
                Text("This will generate meals for all days in this plan based on your preferences. Continue?")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("No Meal Plans")
                .font(.title2)
                .bold()
            
            Text("Create a meal plan to organize your weekly meals")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingNewPlanSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Meal Plan")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private var selectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.mealPlans, id: \.id) { plan in
                    Button(action: {
                        viewModel.selectMealPlan(plan)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(viewModel.formatMealPlanDateRange(plan))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(width: 200)
                        .background(viewModel.currentMealPlan?.id == plan.id ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.currentMealPlan?.id == plan.id ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func mealPlanDetailView(for mealPlan: MealPlan) -> some View {
        VStack {
            HStack {
                Text(mealPlan.name)
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Menu {
                    Button(action: {
                        showingGenerateAlert = true
                    }) {
                        Label("Generate Recipes", systemImage: "wand.and.stars")
                    }
                    
                    Button(action: {
                        _ = viewModel.generateShoppingList()
                    }) {
                        Label("Create Shopping List", systemImage: "cart.badge.plus")
                    }
                    
                    Button(role: .destructive, action: {
                        if let currentPlan = viewModel.currentMealPlan {
                            viewModel.deleteMealPlan(currentPlan)
                        }
                    }) {
                        Label("Delete Plan", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView("Generating meal plan...")
                    .padding()
            } else if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                // Days and meals
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        if let days = mealPlan.days?.sorted(by: { $0.date < $1.date }) {
                            ForEach(days, id: \.id) { day in
                                Section {
                                    if let meals = day.meals {
                                        ForEach(meals, id: \.id) { meal in
                                            MealRow(meal: meal, day: day)
                                        }
                                    } else {
                                        Text("No meals planned")
                                            .foregroundColor(.secondary)
                                            .padding()
                                    }
                                } header: {
                                    dayHeader(for: day.date)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func dayHeader(for date: Date) -> some View {
        HStack {
            Text(date, style: .date)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

struct MealRow: View {
    let meal: MealPlanMeal
    let day: MealPlanDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.type.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let recipe = meal.recipe {
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    HStack {
                        // Recipe image
                        if let imageURL = recipe.image {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.3))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        } else {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            HStack {
                                Label("\(recipe.readyInMinutes) min", systemImage: "clock")
                                    .font(.caption)
                                
                                Text("•")
                                    .font(.caption)
                                
                                Label("\(recipe.servings) servings", systemImage: "person.2")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.leading, 4)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {
                    // TODO: Navigate to recipe selection
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        
                        Text("Add Recipe")
                            .foregroundColor(.accentColor)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct NewMealPlanView: View {
    @ObservedObject var viewModel: MealPlanViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Plan Details")) {
                    TextField("Plan Name", text: $viewModel.planName)
                    
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    
                    Stepper("Number of Days: \(viewModel.numberOfDays)", value: $viewModel.numberOfDays, in: 1...14)
                }
                
                Section {
                    Button(action: {
                        viewModel.createMealPlan()
                        dismiss()
                    }) {
                        Text("Create Plan")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(viewModel.planName.isEmpty)
                }
            }
            .navigationTitle("New Meal Plan")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    MealPlanView()
        .environmentObject(MealPlanViewModel(
            mealPlanService: MealPlanService(
                modelContext: ModelContext(ModelContainer.shared),
                recipeRepository: RecipeRepository(modelContext: ModelContext(ModelContainer.shared))
            ),
            userPreferencesService: UserPreferencesService(modelContext: ModelContext(ModelContainer.shared))
        ))
} 
