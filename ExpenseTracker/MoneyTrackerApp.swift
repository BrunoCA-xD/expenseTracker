import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                MonthlyFilterView()
                    .tabItem {
                        Label("Tracker", systemImage: "dollarsign.circle")
                    }
                
                DataManagementView()
                    .tabItem {
                        Label("Data", systemImage: "gear")
                    }
            }
            .modelContainer(for: [Transaction.self, Category.self, Account.self, TransactionAdjustment.self, CategoryEstimate.self])
        }
    }
}
