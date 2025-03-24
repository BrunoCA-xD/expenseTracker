import SwiftUI
import SwiftData

struct AddAdjustmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let transaction: Transaction
    
    @State private var selectedDate = Date()
    @State private var newAmount: Double // Inicializado com o valor base
    @State private var isPermanent = false
    
    init(transaction: Transaction) {
        self.transaction = transaction
        self._newAmount = State(initialValue: abs(transaction.initialBaseAmount)) // Usa a magnitude do valor base
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Adjustment Details") {
                    DatePicker("Start Date", selection: $selectedDate, displayedComponents: .date)
                    CurrencyTextField(value: $newAmount)
                    Toggle("Permanent Change", isOn: $isPermanent)
                }
            }
            .navigationTitle("Add Adjustment")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAdjustment()
                        dismiss()
                    }
                    .disabled(newAmount == 0.0)
                }
            }
        }
    }
    
    private func saveAdjustment() {
        // Preserva o sinal da transação original
        let adjustedAmount = transaction.initialBaseAmount < 0 ? -abs(newAmount) : abs(newAmount)
        let adjustment = TransactionAdjustment(startDate: selectedDate, amount: adjustedAmount, isPermanent: isPermanent)
        transaction.adjustments.append(adjustment)
        try? modelContext.save()
    }
}

#Preview {
    AddAdjustmentView(transaction: Transaction(
        title: "Test",
        initialBaseAmount: -150.0,
        date: Date(),
        isRecurring: true,
        recurrenceType: .monthly,
        numberOfInstallments: nil,
        endDate: nil,
        category: nil,
        account: nil
        
    ))
    .modelContainer(for: [Transaction.self, TransactionAdjustment.self], inMemory: true)
}
