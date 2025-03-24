import SwiftUI
import SwiftData

@main
struct MoneyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            MonthlyFilterView()
                .modelContainer(for: [Transaction.self, Category.self, Account.self, TransactionAdjustment.self])
        }
    }
}
