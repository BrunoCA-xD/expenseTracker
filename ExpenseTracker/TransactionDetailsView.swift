import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let transaction: Transaction
    @State private var showingAddAdjustment = false
    @State private var hasEndDate: Bool // Reflete se há endDate
    @State private var endDate: Date
    @State private var showingDeleteConfirmation = false
    
    init(transaction: Transaction) {
        self.transaction = transaction
        self._hasEndDate = State(initialValue: transaction.endDate != nil)
        self._endDate = State(initialValue: transaction.endDate ?? Date())
    }
    
    var body: some View {
        Form {
            Section("Details") {
                Text("Title: \(transaction.title)")
                Text("Initial Base Amount: \(transaction.initialBaseAmount, specifier: "%.2f")")
                Text("Date: \(transaction.date, style: .date)")
                Text("Recurring: \(transaction.isRecurring ? "Yes (\(transaction.recurrenceType.rawValue))" : "No")")
                if let installments = transaction.numberOfInstallments {
                    Text("Number of Installments: \(installments)")
                }
                if let category = transaction.category {
                    Text("Category: \(category.name)")
                    if let estimate = category.estimateForMonth(month: Calendar.current.component(.month, from: transaction.date), year: Calendar.current.component(.year, from: transaction.date)) {
                        Text("Monthly Estimate: \(estimate, specifier: "%.2f")")
                    }
                }
                if let account = transaction.account {
                    Text("Account: \(account.name)")
                }
            }
            
            if transaction.isRecurring {
                Section("Recurrence Options") {
                    Toggle("Set End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    Button("Save End Date") {
                        transaction.endDate = hasEndDate ? endDate : nil
                        try? modelContext.save()
                    }
                }
                
                Section("Adjustments") {
                    if transaction.adjustments.isEmpty {
                        Text("No adjustments yet.")
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(transaction.adjustments.sorted { $0.startDate < $1.startDate }) { adjustment in
                            HStack {
                                Text(adjustment.startDate, style: .date)
                                Spacer()
                                Text("\(adjustment.amount, specifier: "%.2f") \(adjustment.isPermanent ? "(Permanent)" : "(One-Time)")")
                            }
                        }
                        .onDelete(perform: deleteAdjustment)
                    }
                }
                Section {
                    Button("Add Adjustment") {
                        showingAddAdjustment = true
                    }
                }
            }
            Section {
                Button("Delete Transaction") {
                    showingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Transaction Details")
        .sheet(isPresented: $showingAddAdjustment) {
            AddAdjustmentView(transaction: transaction)
        }
        .confirmationDialog(
            "Delete Transaction",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(transaction)
                try? modelContext.save()
                dismiss() // Fecha a view após o feedback
            }
        } message: {
            Text(transaction.isRecurring ?
                 "Are you sure you want to delete '\(transaction.title)'? This is a recurring transaction and will remove all future occurrences." :
                    "Are you sure you want to delete '\(transaction.title)'?")
        }
        
    }
    
    private func deleteAdjustment(at offsets: IndexSet) {
        for index in offsets {
            let adjustment = transaction.adjustments.sorted { $0.startDate < $1.startDate }[index]
            modelContext.delete(adjustment)
        }
        try? modelContext.save()
    }
}
