import Foundation
import SwiftData

enum RecurrenceType: String, Codable {
    case none = "None"
    case monthly = "Monthly"
    case weekly = "Weekly"
    
    var description: String {
        switch self {
        case .none: return "Sem recorrência"
        case .monthly: return "Mensal"
        case .weekly: return "Semanal"
        }
    }
}

@Model
class Transaction {
    var id: UUID = UUID()
    var title: String
    var initialBaseAmount: Double // Valor base inicial
    var date: Date // Data inicial
    var isRecurring: Bool
    var recurrenceType: RecurrenceType
    var numberOfInstallments: Int? // nil para infinito
    var endDate: Date?
    @Relationship(deleteRule: .nullify) var category: Category?
    @Relationship(deleteRule: .nullify) var account: Account?
    @Relationship(deleteRule: .cascade) var adjustments: [TransactionAdjustment] = [] // Ajustes de valor
    
    init(title: String, initialBaseAmount: Double, date: Date, isRecurring: Bool, recurrenceType: RecurrenceType, numberOfInstallments: Int?, endDate: Date?, category: Category?, account: Account?) {
        self.title = title
        self.initialBaseAmount = initialBaseAmount
        self.date = date
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.numberOfInstallments = numberOfInstallments
        self.endDate = endDate
        self.category = category
        self.account = account
    }
    
    func occurrencesForPeriod(startDate: Date, endDate: Date) -> [(date: Date, amount: Double)] {
            let calendar = Calendar.current
            var occurrences: [(Date, Double)] = []
            
            if !isRecurring || recurrenceType == .none {
                if date >= startDate && date <= endDate {
                    let amount = getAmount(for: date)
                    occurrences.append((date: date, amount: amount))
                }
            } else {
                var currentDate = date
                let maxOccurrences = numberOfInstallments ?? Int.max
                var occurrenceCount = 0
                
                while occurrenceCount < maxOccurrences && currentDate <= endDate {
                    if currentDate >= startDate {
                        let amount = getAmount(for: currentDate)
                        occurrences.append((date: currentDate, amount: amount))
                    }
                    switch recurrenceType {
                    case .monthly:
                        guard let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
                        currentDate = nextDate
                    case .weekly:
                        guard let nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) else { break }
                        currentDate = nextDate
                    case .none:
                        break
                    }
                    occurrenceCount += 1
                    if currentDate > endDate { break }
                }
            }
            
            return occurrences
        }
    
    // Determina o valor para uma data específica
    func getAmount(for date: Date) -> Double {
        let calendar = Calendar.current
        let sortedAdjustments = adjustments.sorted { $0.startDate < $1.startDate }
        
        if let oneTime = sortedAdjustments.first(where: { calendar.isDate($0.startDate, equalTo: date, toGranularity: .month) && !$0.isPermanent }) {
            return oneTime.amount
        } else if let lastPermanent = sortedAdjustments.last(where: { $0.startDate <= date && $0.isPermanent }) {
            return lastPermanent.amount
        } else {
            return initialBaseAmount
        }
    }
}

@Model
class TransactionAdjustment {
    var id: UUID = UUID()
    var startDate: Date // Data a partir da qual o ajuste aplica
    var amount: Double // Novo valor
    var isPermanent: Bool // True para mudança permanente, False para pontual
    
    init(startDate: Date, amount: Double, isPermanent: Bool) {
        self.startDate = startDate
        self.amount = amount
        self.isPermanent = isPermanent
    }
}

@Model
class Category {
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade) var estimates: [CategoryEstimate] = [] // Estimativas por mês
    
    init(name: String) {
        self.name = name
    }
    
    func estimateForMonth(month: Int, year: Int) -> Double? {
        estimates.first { estimate in
            let components = Calendar.current.dateComponents([.month, .year], from: estimate.date)
            return components.month == month && components.year == year
        }?.amount
    }
}

@Model
class CategoryEstimate {
    var id: UUID = UUID()
    var date: Date // Data representando o mês/ano da estimativa
    var amount: Double
    
    init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
}

@Model
class Account {
    var id: UUID = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
