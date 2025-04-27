import Foundation
import SwiftData
import SwiftUI

struct Occurrence {
    let transaction: Transaction
    let date: Date
    let amount: Double
    let installmentInfo: String?
}

class MonthlyFilterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var selectedType: TransactionTypeFilter?
    @Published var selectedCategory: Category? = nil
    @Published var selectedAccount: Account? = nil
    @Published var showingAddTransaction = false
    @Published var categories: [Category] // Público para acesso na view
    @Published var accounts: [Account] // Público para acesso na view
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private var transactions: [Transaction]
    
    // MARK: - Enums
    enum TransactionTypeFilter: String, CaseIterable, Identifiable {
        case income = "Income"
        case expense = "Expense"
        
        var id: String { rawValue }
    }
    
    // MARK: - Computed Properties
    var filteredOccurrences: [Occurrence] {
        let calendar = Calendar.current
        
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
                return Occurrence(transaction: transaction, date: date, amount: amount, installmentInfo: installmentInfo)
            }
        }
        
        occurrences = occurrences.filter { occurrence in
            switch selectedType {
            case .income: return occurrence.amount >= 0
            case .expense: return occurrence.amount < 0
            case .none: return true
            }
        }
        
        if let category = selectedCategory {
            occurrences = occurrences.filter { $0.transaction.category == category }
        }
        
        if let account = selectedAccount {
            occurrences = occurrences.filter { $0.transaction.account == account }
        }
        
        return occurrences.sorted { $0.date > $1.date }
    }
    
    var realBalance: Double {
        filteredOccurrences.reduce(0) { $0 + $1.amount }
    }
    
    var estimatedBalance: Double {
        categories.reduce(0) { total, category in
            let estimatesInPeriod = category.estimates.filter { estimate in
                estimate.date >= startDate && estimate.date <= endDate
            }
            return total + estimatesInPeriod.reduce(0) { $0 + $1.amount }
        }
    }
    
    var totalBalance: Double {
        realBalance + estimatedBalance
    }
    
    var periodString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return "\(formatter.string(from: startDate)) até \(formatter.string(from: endDate))"
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Inicializar dia padrão
        let defaultDay = UserDefaults.standard.integer(forKey: "defaultDay") > 0 ? UserDefaults.standard.integer(forKey: "defaultDay") : 12
        let calendar = Calendar.current
        let now = Date()
        
        var startComponents = calendar.dateComponents([.year, .month], from: now)
        startComponents.day = defaultDay
        startComponents.month = (startComponents.month ?? 1)
        self.startDate = calendar.date(from: startComponents) ?? now
        
        var endComponents = calendar.dateComponents([.year, .month], from: now)
        endComponents.day = defaultDay
        endComponents.month = (startComponents.month ?? 1) + 1
        self.endDate = calendar.date(from: endComponents) ?? now
        
        // Carregar dados
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let categoryDescriptor = FetchDescriptor<Category>()
        let accountDescriptor = FetchDescriptor<Account>()
        do {
            self.transactions = try modelContext.fetch(transactionDescriptor)
            self.categories = try modelContext.fetch(categoryDescriptor)
            self.accounts = try modelContext.fetch(accountDescriptor)
        } catch {
            print("Error fetching data: \(error)")
            self.transactions = []
            self.categories = []
            self.accounts = []
        }
    }
    
    // MARK: - Methods
    func fetchData() {
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let categoryDescriptor = FetchDescriptor<Category>()
        let accountDescriptor = FetchDescriptor<Account>()
        do {
            self.transactions = try modelContext.fetch(transactionDescriptor)
            self.categories = try modelContext.fetch(categoryDescriptor)
            self.accounts = try modelContext.fetch(accountDescriptor)
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    
    func previousMonth() {
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate) ?? Date()
        endDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? Date()
    }
    
    func nextMonth() {
        startDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? Date()
        endDate = Calendar.current.date(byAdding: .month, value: 1, to: endDate) ?? Date()
    }
}
