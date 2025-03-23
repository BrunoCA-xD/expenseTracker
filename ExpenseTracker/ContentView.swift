import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @State private var showingAddTransaction = false
    
    private var totalBalance: Double {
        transactions.reduce(0) { $0 + $1.initialBaseAmount } // Apenas o valor inicial para simplicidade
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Balance: \(totalBalance, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(totalBalance >= 0 ? .green : .red)
                    .padding()
                
                List {
                    ForEach(transactions) { transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transaction.title)
                                        .font(.headline)
                                    Text(transaction.date, style: .date)
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                    if let category = transaction.category {
                                        Text(category.name)
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    if transaction.isRecurring {
                                        Text(transaction.numberOfInstallments != nil ? "\(transaction.numberOfInstallments!) installments" : "Fixed")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                    }
                                }
                                Spacer()
                                Text("\(transaction.initialBaseAmount, specifier: "%.2f")")
                                    .foregroundStyle(transaction.initialBaseAmount >= 0 ? .green : .red)
                            }
                        }
                    }
                    .onDelete(perform: deleteTransaction)
                }
            }
            .navigationTitle("Money Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: MonthlyFilterView()) {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
    
    private func deleteTransaction(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(transactions[index])
        }
        try? modelContext.save()
    }
}

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let transaction: Transaction
    @State private var showingEditAdjustment = false
    @State private var selectedDate = Date()
    @State private var newAmount = ""
    @State private var isPermanent = false
    
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
            }
            
            Section("Adjustments") {
                ForEach(transaction.adjustments.sorted { $0.startDate < $1.startDate }) { adjustment in
                    HStack {
                        Text(adjustment.startDate, style: .date)
                        Spacer()
                        Text("\(adjustment.amount, specifier: "%.2f") \(adjustment.isPermanent ? "(Permanent)" : "(One-Time)")")
                    }
                }
            }
            
            if transaction.isRecurring {
                Section("Add Adjustment") {
                    DatePicker("Start Date", selection: $selectedDate, displayedComponents: .date)
                    TextField("New Amount", text: $newAmount)
                        .keyboardType(.decimalPad)
                    Toggle("Permanent Change", isOn: $isPermanent)
                    Button("Save Adjustment") {
                        if let amount = Double(newAmount) {
                            let adjustment = TransactionAdjustment(startDate: selectedDate, amount: amount, isPermanent: isPermanent)
                            transaction.adjustments.append(adjustment)
                            try? modelContext.save()
                            newAmount = ""
                            showingEditAdjustment = false
                        }
                    }
                    .disabled(newAmount.isEmpty || Double(newAmount) == nil)
                }
            }
        }
        .navigationTitle("Transaction Details")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, TransactionAdjustment.self], inMemory: true)
}
