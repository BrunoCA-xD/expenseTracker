import SwiftUI
import SwiftData

struct MonthlyFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category] // Para o filtro de categorias
    @Query private var accounts: [Account]
    
    @State private var selectedDate = Date()
    @State private var selectedType: TransactionTypeFilter? = nil // Filtro de tipo
    @State private var selectedCategory: Category? = nil // Filtro de categoria
    @State private var selectedAccount: Account? = nil
    
    // Enum para o filtro de tipo
    enum TransactionTypeFilter: String, CaseIterable, Identifiable {
        case income = "Income"
        case expense = "Expense"
        
        var id: String { rawValue }
    }
    
    private var filteredOccurrences: [(transaction: Transaction, date: Date, amount: Double)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedDate)
        let month = components.month!
        let year = components.year!
        
        // Filtra as transações com base no mês e ano
        var occurrences = transactions.flatMap { transaction in
            transaction.occurrencesForMonth(month: month, year: year).map { (transaction, $0.date, $0.amount) }
        }
        
        // Aplica filtro de tipo
        occurrences = occurrences.filter { occurrence in
            switch selectedType {
            case .income:
                return occurrence.2 >= 0
            case .expense:
                return occurrence.2 < 0
            case .none:
                return true
            }
        }
        
        // Aplica filtro de categoria
        if let category = selectedCategory {
            occurrences = occurrences.filter { $0.0.category == category }
        }
        
        if let account = selectedAccount {
            occurrences = occurrences.filter { $0.0.account == account }
        }
        
        return occurrences
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
                
                // Filtros
                HStack(spacing: 20) {
                    Menu {
                        Button("All") { selectedType = nil }
                        Button("Income") { selectedType = .income }
                        Button("Expense") { selectedType = .expense }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedType?.rawValue ?? "Tipo" )
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                    
                    // Filtro de Categoria
                    Menu {
                        Button("All") { selectedCategory = nil }
                        ForEach(categories) { category in
                            Button(category.name) { selectedCategory = category }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCategory?.name ?? "Category")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                    
                    Menu {
                        Button("All") { selectedAccount = nil }
                        ForEach(accounts) { account in
                            Button(account.name) { selectedAccount = account }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedAccount?.name ?? "Account")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal)
                
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
        .modelContainer(for: [Transaction.self, Category.self, TransactionAdjustment.self], inMemory: true)
}
