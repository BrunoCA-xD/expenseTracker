import Foundation
import SwiftData

class TransactionDetailViewModel: ObservableObject {
    @Published var transaction: Transaction
    @Published var hasEndDate: Bool
    @Published var endDate: Date
    @Published var showingAddAdjustment: Bool = false
    @Published var showingDeleteConfirmation: Bool = false
    
    private let modelContext: ModelContext
    
    init(transaction: Transaction, modelContext: ModelContext) {
        self.transaction = transaction
        self.modelContext = modelContext
        self.hasEndDate = transaction.endDate != nil
        self.endDate = transaction.endDate ?? Date()
    }
    
    func saveEndDate() {
        transaction.endDate = hasEndDate ? endDate : nil
        try? modelContext.save()
    }
    
    func deleteTransaction() {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
    
    func deleteAdjustment(at offsets: IndexSet) {
        let sortedAdjustments = transaction.adjustments.sorted { $0.startDate < $1.startDate }
        for index in offsets {
            let adjustment = sortedAdjustments[index]
            modelContext.delete(adjustment)
        }
        try? modelContext.save()
    }
    
    func estimateForMonth(date: Date) -> Double? {
        guard let category = transaction.category else { return nil }

        let month = Calendar.current.component(.month, from: date)
        let year =  Calendar.current.component(.year, from: date)        
        return category.estimateForMonth(month: month, year: year)
    }
}
