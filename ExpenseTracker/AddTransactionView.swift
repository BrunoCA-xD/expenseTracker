import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var categories: [Category]
    
    @State private var title = ""
    @State private var initialBaseAmount: Double = 0.0
    @State private var isIncome = false
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var recurrenceType = RecurrenceType.monthly
    @State private var numberOfInstallments = ""
    @State private var selectedCategory: Category? // Opcional, pode ser nil
    @State private var newCategoryName = ""
    @State private var showingAddCategory = false
    @State private var refreshTrigger = UUID() // Força atualização da view
    
    private var finalInitialBaseAmount: Double? {
        let value = isIncome ? initialBaseAmount : -initialBaseAmount
        return value != 0.0 ? value : nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Title", text: $title)
                    CurrencyTextField(value: $initialBaseAmount)
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("Type", selection: $isIncome) {
                            Text("Outcome").tag(false)
                            Text("Income").tag(true)
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                    DatePicker("Start Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Recurrence") {
                    Toggle("Is Recurring", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Recurrence Type", selection: $recurrenceType) {
                            Text("Monthly").tag(RecurrenceType.monthly)
                            Text("Weekly").tag(RecurrenceType.weekly)
                        }
                        TextField("Number of Installments (leave empty for fixed)", text: $numberOfInstallments)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(Category?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    }
                    Button("Add New Category") {
                        showingAddCategory = true
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                        dismiss()
                    }
                    .disabled(!isValid())
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(newCategoryName: $newCategoryName, onSave: {
                    if !newCategoryName.isEmpty {
                        let newCategory = Category(name: newCategoryName)
                        modelContext.insert(newCategory)
                        selectedCategory = newCategory
                        newCategoryName = ""
                        showingAddCategory = false
                    }
                })
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = finalInitialBaseAmount else { return }
        let installments = Int(numberOfInstallments) ?? nil
        
        let newTransaction = Transaction(
            title: title,
            initialBaseAmount: amountValue,
            date: date,
            isRecurring: isRecurring,
            recurrenceType: isRecurring ? recurrenceType : .none,
            numberOfInstallments: installments,
            category: selectedCategory
        )
        modelContext.insert(newTransaction)
        try? modelContext.save()
    }
    
    private func isValid() -> Bool {
        !title.isEmpty && initialBaseAmount != 0 && (!isRecurring || numberOfInstallments.isEmpty || Int(numberOfInstallments) != nil)
    }
}

struct AddCategoryView: View {
    @Binding var newCategoryName: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Category Name", text: $newCategoryName)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(newCategoryName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, TransactionAdjustment.self], inMemory: true)
}
