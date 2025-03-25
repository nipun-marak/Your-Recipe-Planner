import SwiftUI
import SwiftData

struct FavoritesView: View {
    @EnvironmentObject var viewModel: FavoritesViewModel
    @State private var searchText = ""
    @State private var selectedCategory: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.favoriteRecipes.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        searchAndFilterBar
                        
                        if viewModel.filteredRecipes.isEmpty {
                            noSearchResultsView
                        } else {
                            recipeList
                        }
                    }
                }
            }
            .navigationTitle("Favorite Recipes")
            .onAppear {
                viewModel.loadFavorites()
                viewModel.searchText = searchText
                viewModel.selectedCategory = selectedCategory
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "heart.slash")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("No Favorite Recipes")
                .font(.title2)
                .bold()
            
            Text("Recipes you mark as favorites will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search favorites...", text: $searchText)
                    .onChange(of: searchText) { newValue in
                        viewModel.searchText = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    categoryButton(title: "All", category: nil)
                    
                    ForEach(viewModel.getCategories(), id: \.self) { category in
                        categoryButton(title: category.capitalized, category: category)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
    }
    
    private func categoryButton(title: String, category: String?) -> some View {
        Button(action: {
            selectedCategory = category
            viewModel.selectedCategory = category
        }) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedCategory == category ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(selectedCategory == category ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    private var noSearchResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Matching Recipes")
                .font(.title3)
                .bold()
            
            Text("Try adjusting your search or filters")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var recipeList: some View {
        List {
            ForEach(viewModel.filteredRecipes, id: \.id) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    FavoriteRecipeRow(recipe: recipe)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.removeFromFavorites(recipe)
                        }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct FavoriteRecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 16) {
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
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Recipe details
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label("\(recipe.readyInMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let diets = recipe.diets, !diets.isEmpty {
                    Text(diets.prefix(2).joined(separator: ", ").capitalized)
                        .font(.caption)
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesViewModel(recipeRepository: RecipeRepository(modelContext: ModelContext(ModelContainer.shared))))
} 
