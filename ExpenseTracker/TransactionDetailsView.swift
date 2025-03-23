import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let transaction: Transaction
    @State private var showingEditAdjustment = false
    @State private var selectedDate = Date()
    @State private var newAmount: Double = 0.0
    @State private var isPermanent = false
    @State private var showingAddAdjustment = false
    
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
                }
                if let account = transaction.account {
                    Text("Account: \(account.name)")
                }
            }
            
            if transaction.isRecurring {
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
        }
        .navigationTitle("Transaction Details")
        .sheet(isPresented: $showingAddAdjustment) {
            AddAdjustmentView(transaction: transaction)
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
