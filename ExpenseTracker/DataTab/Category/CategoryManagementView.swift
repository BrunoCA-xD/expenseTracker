import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    
    @State private var showingAddCategory = false
    
    var body: some View {
        List {
            Section(header: Text("Categories")) {
                ForEach(categories) { category in
                    NavigationLink(destination: CategoryEditView(category: category)) {
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .font(.headline)
                            if !category.estimates.isEmpty {
                                Text("\(category.estimates.count) estimate(s)")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCategory)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus") { showingAddCategory = true }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(date: Date())
        }
    }
    
    
    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            modelContext.delete(category)
        }
        try? modelContext.save()
    }
}
