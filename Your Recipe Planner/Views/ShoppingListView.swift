import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @EnvironmentObject var viewModel: ShoppingListViewModel
    @State private var showingNewListSheet = false
    @State private var showingShareSheet = false
    @State private var shoppingListURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.shoppingLists.isEmpty {
                    emptyStateView
                } else {
                    VStack {
                        // List selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.shoppingLists, id: \.id) { list in
                                    Button(action: {
                                        viewModel.selectShoppingList(list)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(list.name)
                                                .font(.headline)
                                                .lineLimit(1)
                                            
                                            Text(formatDate(list.createdAt))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .frame(width: 200)
                                        .background(viewModel.currentShoppingList?.id == list.id ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.currentShoppingList?.id == list.id ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        
                        // Shopping list content
                        if let currentList = viewModel.currentShoppingList {
                            shoppingListDetailView(for: currentList)
                        } else {
                            Text("Select a shopping list to view its items")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingNewListSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                if viewModel.currentShoppingList != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if let url = viewModel.shareShoppingList() {
                                shoppingListURL = url
                                showingShareSheet = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewListSheet) {
                NewShoppingListView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadShoppingLists()
                if viewModel.currentShoppingList == nil && !viewModel.shoppingLists.isEmpty {
                    viewModel.selectShoppingList(viewModel.shoppingLists[0])
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shoppingListURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("No Shopping Lists")
                .font(.title2)
                .bold()
            
            Text("Create a shopping list to keep track of ingredients you need to buy")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingNewListSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Shopping List")
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
    
    private func shoppingListDetailView(for shoppingList: ShoppingList) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(shoppingList.name)
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                if let items = shoppingList.items, !items.isEmpty {
                    HStack(spacing: 4) {
                        Text("\(viewModel.getCompletedItemCount()) of \(viewModel.getTotalItemCount())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: viewModel.getCompletionPercentage())
                            .frame(width: 50)
                    }
                }
                
                Menu {
                    Button(role: .destructive, action: {
                        if let currentList = viewModel.currentShoppingList {
                            viewModel.deleteShoppingList(currentList)
                        }
                    }) {
                        Label("Delete List", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if let items = shoppingList.items, !items.isEmpty {
                List {
                    ForEach(items, id: \.id) { item in
                        ShoppingItemRow(item: item, viewModel: viewModel)
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Items Yet")
                        .font(.title3)
                        .bold()
                    
                    Text("Add items to your shopping list or generate a list from a meal plan")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    @ObservedObject var viewModel: ShoppingListViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                viewModel.toggleItemCompletion(item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ingredient.name)
                    .font(.headline)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                Text("\(String(format: "%.1f", item.quantity)) \(item.ingredient.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Quantity stepper
            if !item.isCompleted {
                Stepper("", value: Binding(
                    get: { item.quantity },
                    set: { newValue in
                        viewModel.updateItemQuantity(item, newQuantity: newValue)
                    }
                ), in: 0.1...100.0, step: 0.5)
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeItemFromList(item)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct NewShoppingListView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("List Details")) {
                    TextField("List Name", text: $viewModel.newListName)
                }
                
                Section {
                    Button(action: {
                        viewModel.createShoppingList()
                        dismiss()
                    }) {
                        Text("Create List")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(viewModel.newListName.isEmpty)
                }
            }
            .navigationTitle("New Shopping List")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

// Helper for sharing
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to do here
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ShoppingList.self,  // Add all your SwiftData models here
        configurations: config
    )
    
    return ShoppingListView()
        .environmentObject(ShoppingListViewModel(
            shoppingListService: ShoppingListService(
                modelContext: ModelContext(container)
            )
        ))
}
