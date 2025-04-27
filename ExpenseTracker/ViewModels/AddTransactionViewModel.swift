import Foundation
import SwiftData

class AddTransactionViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var amount: Double = 0.0
    @Published var date: Date = Date()
    @Published var isIncome: Bool = false
    @Published var isRecurring: Bool = false
    @Published var recurrenceType: RecurrenceType = .none
    @Published var numberOfInstallments: Int? = nil
    @Published var selectedCategory: Category?
    @Published var selectedAccount: Account?
    
    @Published var categories: [Category] = []
    @Published var accounts: [Account] = []
    
    @Published var showingAddCategory: Bool = false
    @Published var showingAddAccount: Bool = false
    
    private let modelContext: ModelContext
    
    var isFormValid: Bool {
        !title.isEmpty && amount != 0
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }
    
    func fetchData() {
        let categoryFetch = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        let accountFetch = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.name)])
        categories = (try? modelContext.fetch(categoryFetch)) ?? []
        accounts = (try? modelContext.fetch(accountFetch)) ?? []
    }
    
    func saveTransaction() {
        let finalAmount = isIncome ? +amount : -amount
        let transaction = Transaction(
            title: title,
            initialBaseAmount: finalAmount,
            date: date,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType,
            numberOfInstallments: numberOfInstallments,
            endDate: nil,
            category: selectedCategory,
            account: selectedAccount
        )
        modelContext.insert(transaction)
        try? modelContext.save()
        resetForm()
    }
    
    private func resetForm() {
        title = ""
        amount = 0.0
        date = Date()
        isRecurring = false
        recurrenceType = .none
        numberOfInstallments = 0
        selectedCategory = nil
        selectedAccount = nil
        showingAddCategory = false
        showingAddAccount = false
    }
}
