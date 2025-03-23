import SwiftUI
import SwiftData


struct MonthlyFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @State private var selectedDate = Date()
    
    private var filteredOccurrences: [(transaction: Transaction, date: Date, amount: Double)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedDate)
        let month = components.month!
        let year = components.year!
        
        return transactions.flatMap { transaction in
            transaction.occurrencesForMonth(month: month, year: year).map { (transaction, $0.date, $0.amount) }
        }
    }
    
    private var monthlyBalance: Double {
        filteredOccurrences.reduce(0) { $0 + $1.amount }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                MonthYearPicker(selectedDate: $selectedDate)
                
                Text("Balance for \(monthYearString): \(monthlyBalance, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(monthlyBalance >= 0 ? .green : .red)
                    .padding()
                
                List(filteredOccurrences, id: \.date) { occurrence in
                    NavigationLink(destination: TransactionDetailView(transaction: occurrence.transaction)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(occurrence.transaction.title)
                                    .font(.headline)
                                Text(occurrence.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                if let category = occurrence.transaction.category {
                                    Text(category.name)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            Spacer()
                            Text("\(occurrence.amount, specifier: "%.2f")")
                                .foregroundStyle(occurrence.amount >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle("Monthly Balance")
        }
    }
}

#Preview {
    MonthlyFilterView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
