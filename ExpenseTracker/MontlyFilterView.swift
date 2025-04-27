import SwiftUI
import SwiftData

struct MonthlyFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category] // Para o filtro de categorias
    @Query private var accounts: [Account]
    
    @State private var startDate: Date = {
        let defaultDay = UserDefaults.standard.integer(forKey: "defaultDay") > 0 ? UserDefaults.standard.integer(forKey: "defaultDay") : 12
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = defaultDay
        return calendar.date(from: components) ?? now
    }()
    @State private var endDate: Date = {
        let defaultDay = UserDefaults.standard.integer(forKey: "defaultDay") > 0 ? UserDefaults.standard.integer(forKey: "defaultDay") : 12
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = defaultDay
        components.month = (components.month ?? 1) + 1 // Mês passado
        return calendar.date(from: components) ?? now
    }()
    @State private var selectedType: TransactionTypeFilter? = nil // Filtro de tipo
    @State private var selectedCategory: Category? = nil // Filtro de categoria
    @State private var selectedAccount: Account? = nil
    @State private var showingAddTransaction = false
    let calendar = Calendar.current
    
    // Enum para o filtro de tipo
    enum TransactionTypeFilter: String, CaseIterable, Identifiable {
        case income = "Income"
        case expense = "Expense"
        
        var id: String { rawValue }
    }
    
    private var filteredOccurrences: [(transaction: Transaction, date: Date, amount: Double, installmentInfo: String?)] {
        
        var occurrences = transactions.flatMap { transaction in
            let periodOccurrences = transaction.occurrencesForPeriod(startDate: startDate, endDate: endDate)
            return periodOccurrences.map { (date, amount) in
                var installmentInfo: String? = nil
                if transaction.isRecurring && transaction.numberOfInstallments != nil {
                    let allOccurrences = transaction.occurrencesForPeriod(
                        startDate: transaction.date,
                        endDate: transaction.endDate ?? Date.distantFuture
                    )
                    if let total = transaction.numberOfInstallments,
                       let index = allOccurrences.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                        installmentInfo = "\(index + 1)/\(total)"
                    }
                }
                return (transaction, date, amount, installmentInfo)
            }
        }
        
        // Aplica filtros adicionais
        occurrences = occurrences.filter { occurrence in
            switch selectedType {
            case .none: return true
            case .income: return occurrence.2 >= 0
            case .expense: return occurrence.2 < 0
            }
        }
        
        if let category = selectedCategory {
            occurrences = occurrences.filter { $0.0.category == category }
        }
        
        if let account = selectedAccount {
            occurrences = occurrences.filter { $0.0.account == account }
        }
        
        return occurrences.sorted { $0.1 > $1.1 }
    }
    
    private var realBalance: Double {
        filteredOccurrences.reduce(0) { $0 + $1.amount }
    }
    
    private var estimatedBalance: Double {
        categories.reduce(0) { total, category in
            let estimatesInPeriod = category.estimates.filter { estimate in
                estimate.date >= startDate && estimate.date <= endDate
            }
            return total + estimatesInPeriod.reduce(0) { $0 + $1.amount }
        }
    }
    
    private var totalBalance: Double {
        realBalance + estimatedBalance
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        startDate = calendar.date(byAdding: .month, value: -1, to: startDate) ?? Date()
                        endDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? Date()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Button {
                        startDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? Date()
                        endDate = calendar.date(byAdding: .month, value: 1, to: endDate) ?? Date()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Balance: \(totalBalance, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(totalBalance >= 0 ? .green : .red)
                    Text("Real Balance: \(realBalance, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Text("Estimated Balance: \(estimatedBalance, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)
                
                List(filteredOccurrences, id: \.date) { occurrence in
                    NavigationLink(destination: TransactionDetailView(transaction: occurrence.transaction)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(occurrence.0.title)
                                        .font(.headline)
                                    if occurrence.0.isRecurring {
                                        Image(systemName: "arrow.2.circlepath")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if let installmentInfo = occurrence.installmentInfo {
                                        Text(installmentInfo)
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                            .padding(.horizontal, 4)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                Text(occurrence.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                if let category = occurrence.transaction.category {
                                    Text(category.name)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    if let estimate = category.estimates.first(where: { Calendar.current.isDate($0.date, equalTo: occurrence.date, toGranularity: .month) }) {
                                        Text("Estimate: \(estimate.amount, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                if let account = occurrence.transaction.account {
                                    Text(account.name)
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                }
                            }
                            Spacer()
                            Text("\(occurrence.amount, specifier: "%.2f")")
                                .foregroundStyle(occurrence.amount >= 0 ? .green : .red)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Money Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
}

#Preview {
    MonthlyFilterView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, TransactionAdjustment.self, CategoryEstimate.self], inMemory: true)
}
