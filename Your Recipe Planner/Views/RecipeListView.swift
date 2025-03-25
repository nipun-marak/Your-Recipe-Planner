import SwiftUI
import Combine

struct RecipeListView: View {
    @EnvironmentObject var viewModel: RecipeListViewModel
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search recipes...", text: $viewModel.searchQuery)
                        .onSubmit {
                            viewModel.searchRecipes()
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if viewModel.isLoading && viewModel.recipes.isEmpty {
                    Spacer()
                    ProgressView("Loading recipes...")
                    Spacer()
                } else if viewModel.recipes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No recipes found")
                            .font(.headline)
                        Button("Try random recipes") {
                            viewModel.fetchRandomRecipes()
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.recipes, id: \.id) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onAppear {
                                        if recipe == viewModel.recipes.last {
                                            viewModel.loadMore()
                                        }
                                    }
                                    .onTapGesture {
                                        // Will be handled by NavigationLink
                                    }
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Discover Recipes")
            .onAppear {
                if viewModel.recipes.isEmpty {
                    viewModel.fetchRandomRecipes()
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    @EnvironmentObject var viewModel: RecipeListViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            VStack(alignment: .leading, spacing: 8) {
                // Recipe image
                Group {
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
                    } else {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    // Recipe title
                    Text(recipe.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    // Recipe info
                    HStack {
                        Label("\(recipe.readyInMinutes) min", systemImage: "clock")
                            .font(.caption)
                        
                        Spacer()
                        
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                            .font(.caption)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleFavorite(recipe)
                        }) {
                            Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(recipe.isFavorite ? .red : .gray)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    // Diet labels
                    if let diets = recipe.diets, !diets.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(diets.prefix(3), id: \.self) { diet in
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
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: RecipeListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDiet: String?
    @State private var selectedCuisine: String?
    @State private var selectedIntolerances: [String] = []
    @State private var maxReadyTime: Int?
    
    private let cuisines = [
        "African", "American", "British", "Cajun", "Caribbean", "Chinese", "Eastern European",
        "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese",
        "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern",
        "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Diet")) {
                    Picker("Diet Type", selection: $selectedDiet) {
                        Text("Any").tag(String?.none)
                        ForEach(viewModel.getDietOptions(), id: \.self) { diet in
                            Text(diet.capitalized).tag(diet as String?)
                        }
                    }
                }
                
                Section(header: Text("Cuisine")) {
                    Picker("Cuisine Type", selection: $selectedCuisine) {
                        Text("Any").tag(String?.none)
                        ForEach(cuisines, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine as String?)
                        }
                    }
                }
                
                Section(header: Text("Intolerances")) {
                    ForEach(viewModel.getIntoleranceOptions(), id: \.self) { intolerance in
                        Toggle(intolerance.capitalized, isOn: Binding(
                            get: { selectedIntolerances.contains(intolerance) },
                            set: { isSelected in
                                if isSelected {
                                    selectedIntolerances.append(intolerance)
                                } else {
                                    selectedIntolerances.removeAll { $0 == intolerance }
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Ready Time")) {
                    Picker("Maximum Cooking Time", selection: $maxReadyTime) {
                        Text("Any").tag(Int?.none)
                        Text("15 min").tag(15 as Int?)
                        Text("30 min").tag(30 as Int?)
                        Text("45 min").tag(45 as Int?)
                        Text("60 min").tag(60 as Int?)
                    }
                }
                
                Button("Reset Filters") {
                    selectedDiet = nil
                    selectedCuisine = nil
                    selectedIntolerances = []
                    maxReadyTime = nil
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Filter Recipes")
            .navigationBarItems(
                trailing: Button("Apply") {
                    viewModel.selectedDiet = selectedDiet
                    viewModel.selectedCuisine = selectedCuisine
                    viewModel.selectedIntolerances = selectedIntolerances
                    viewModel.maxReadyTime = maxReadyTime
                    
                    // Apply the search with new filters
                    viewModel.searchRecipes()
                    
                    dismiss()
                }
            )
            .onAppear {
                // Initialize with current filters
                selectedDiet = viewModel.selectedDiet
                selectedCuisine = viewModel.selectedCuisine
                selectedIntolerances = viewModel.selectedIntolerances
                maxReadyTime = viewModel.maxReadyTime
            }
        }
    }
}

#Preview {
    RecipeListView()
} 
