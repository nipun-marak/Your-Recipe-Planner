import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var viewModel: RecipeDetailViewModel
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipeRepository: RecipeRepository(modelContext: ModelContext(ModelContainer.shared)), recipe: recipe))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe Image
                if let imageURL = recipe.image {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(height: 250)
                        }
                    }
                } else {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe Info Bar
                    HStack(spacing: 20) {
                        Spacer()
                        
                        VStack {
                            Image(systemName: "clock")
                                .font(.system(size: 24))
                            Text("\(recipe.readyInMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Image(systemName: "person.2")
                                .font(.system(size: 24))
                            Stepper("\(viewModel.servings)", value: $viewModel.servings, in: 1...20)
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        VStack {
                            Button(action: {
                                viewModel.toggleFavorite()
                            }) {
                                Image(systemName: viewModel.recipe?.isFavorite ?? false ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.recipe?.isFavorite ?? false ? .red : .gray)
                            }
                            Text("Favorite")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Diet Labels
                    if let diets = recipe.diets, !diets.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(diets, id: \.self) { diet in
                                    Text(diet.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    
                    // Recipe Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary")
                            .font(.headline)
                        
                        Text(recipe.summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil))
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(viewModel.getAdjustedIngredients(), id: \.id) { ingredient in
                            HStack(alignment: .top) {
                                Text("•")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("\(String(format: "%.1f", ingredient.amount)) \(ingredient.unit) \(ingredient.name)")
                                    .font(.body)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Instructions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                        
                        if let instructions = recipe.instructions, !instructions.isEmpty {
                            let cleanedInstructions = instructions.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                            
                            Text(cleanedInstructions)
                                .font(.body)
                        } else {
                            Text("No instructions available. If you purchased this recipe, please check the source website.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Nutritional Information (if available) - this would come from the API
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutritional Information")
                            .font(.headline)
                        
                        HStack {
                            ForEach(Array(viewModel.getNutritionalInfo().keys.sorted()), id: \.self) { key in
                                VStack {
                                    Text(viewModel.getNutritionalInfo()[key] ?? "")
                                        .font(.subheadline)
                                        .bold()
                                    Text(key)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if key != Array(viewModel.getNutritionalInfo().keys.sorted()).last {
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Source attribution
                    if let sourceUrl = recipe.sourceUrl, !sourceUrl.isEmpty {
                        Divider()
                        
                        HStack {
                            Text("Source:")
                                .foregroundColor(.secondary)
                            Link("View Original Recipe", destination: URL(string: sourceUrl)!)
                        }
                    }
                    
                    // Add to Meal Plan Button
                    Button(action: {
                        // TODO: Handle adding to meal plan
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Meal Plan")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadRecipeDetails(id: recipe.id)
        }
    }
}

// Create a singleton ModelContainer for preview and detail view usage
extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
            MealPlan.self,
            MealPlanDay.self,
            MealPlanMeal.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserPreferences.self,
            NutritionalGoals.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

#Preview {
    NavigationView {
        RecipeDetailView(
            recipe: Recipe(
                id: 1,
                title: "Spaghetti Carbonara",
                summary: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper.",
                readyInMinutes: 30,
                servings: 2,
                diets: ["low FODMAP"]
            )
        )
    }
} 
