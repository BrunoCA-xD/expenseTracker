import Foundation
import SwiftData

enum RecurrenceType: String, Codable {
    case none = "None"
    case monthly = "Monthly"
    case weekly = "Weekly"
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
    @Relationship(deleteRule: .nullify) var category: Category?
    @Relationship(deleteRule: .cascade) var adjustments: [TransactionAdjustment] = [] // Ajustes de valor
    
    init(title: String, initialBaseAmount: Double, date: Date, isRecurring: Bool, recurrenceType: RecurrenceType, numberOfInstallments: Int?, category: Category?) {
        self.title = title
        self.initialBaseAmount = initialBaseAmount
        self.date = date
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.numberOfInstallments = numberOfInstallments
        self.category = category
    }
    
    // Calcula ocorrências para o mês considerando ajustes
    func occurrencesForMonth(month: Int, year: Int) -> [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        var occurrences: [(Date, Double)] = []
        
        if !isRecurring || recurrenceType == .none {
            let components = calendar.dateComponents([.month, .year], from: date)
            if components.month == month && components.year == year {
                let amount = getAmount(for: date)
                return [(date: date, amount: amount)]
            }
            return []
        }
        
        var currentDate = date
        let maxOccurrences = numberOfInstallments ?? Int.max
        var occurrenceCount = 0
        
        while occurrenceCount < maxOccurrences {
            let components = calendar.dateComponents([.month, .year], from: currentDate)
            guard let occurrenceMonth = components.month, let occurrenceYear = components.year else { break }
            
            if occurrenceYear > year || (occurrenceYear == year && occurrenceMonth > month) {
                break
            }
            
            if occurrenceMonth == month && occurrenceYear == year {
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
        }
        
        return occurrences
    }
    
    // Determina o valor para uma data específica
    private func getAmount(for date: Date) -> Double {
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
    
    init(name: String) {
        self.name = name
    }
}
