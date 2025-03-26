import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var newCategoryName = ""
    @State private var estimatedMonthlyAmount: Double = 0.0
    let date: Date // Data para associar a estimativa
    let onCategoryAdded: (Category) -> Void // Callback para retornar a nova categoria
    
    init(date: Date, onCategoryAdded: @escaping (Category) -> Void = { _ in }) {
        self.date = date
        self.onCategoryAdded = onCategoryAdded
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Category Name", text: $newCategoryName)
                CurrencyTextField("Monthly Estimate (R$)", value: $estimatedMonthlyAmount)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveCategory()
                        dismiss()
                    }
                    .disabled(newCategoryName.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let newCategory = Category(name: newCategoryName)
        if estimatedMonthlyAmount != 0.0 {
            let estimate = CategoryEstimate(date: date, amount: estimatedMonthlyAmount)
            newCategory.estimates.append(estimate)
        }
        modelContext.insert(newCategory)
        try? modelContext.save()
        onCategoryAdded(newCategory) // Retorna a nova categoria
    }
}
