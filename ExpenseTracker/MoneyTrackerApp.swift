import SwiftUI
import SwiftData

@main
struct MoneyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self, Category.self])
        }
    }
}
