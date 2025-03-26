import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let category: Category
    
    @State private var name: String
    @State private var isIncome: Bool = false
    @State private var newEstimateAmount: Double = 0.0
    @State private var newEstimateDate = Date()
    
    private var finalEstimateAmount: Double {
        isIncome ? +newEstimateAmount : -newEstimateAmount
    }
    
    init(category: Category) {
        self.category = category
        self._name = State(initialValue: category.name)
    }
    
    var body: some View {
        Form {
            Section("Category Details") {
                TextField("Name", text: $name)
            }
            
            Section("Estimates") {
                ForEach(category.estimates) { estimate in
                    HStack {
                        Text(estimate.date, formatter: monthYearFormatter)
                        Spacer()
                        Text("\(estimate.amount, specifier: "%.2f")")
                            .foregroundStyle(estimate.amount >= 0 ? .green : .red)
                    }
                }
                .onDelete(perform: deleteEstimate)
            }
            
            Section("Add New Estimate") {
                HStack {
                    Text("Type")
                    Spacer()
                    Picker("Type", selection: $isIncome) {
                        Text("Outcome").tag(false)
                        Text("Income").tag(true)
                    }.pickerStyle(SegmentedPickerStyle())
                }
                CurrencyTextField("Estimate Amount (R$)", value: $newEstimateAmount)
                DatePicker("Month", selection: $newEstimateDate, displayedComponents: .date)
                Button("Add Estimate") {
                    let newEstimate = CategoryEstimate(date: newEstimateDate, amount: finalEstimateAmount)
                    category.estimates.append(newEstimate)
                    try? modelContext.save()
                    newEstimateAmount = 0.0
                    newEstimateDate = Date()
                }
                .disabled(newEstimateAmount == 0.0)
            }
        }
        .navigationTitle("Edit Category")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    category.name = name
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func deleteEstimate(at offsets: IndexSet) {
        for index in offsets {
            let estimate = category.estimates[index]
            modelContext.delete(estimate)
        }
        try? modelContext.save()
    }
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}
