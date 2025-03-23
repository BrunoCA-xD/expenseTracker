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

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, TransactionAdjustment.self], inMemory: true)
}
