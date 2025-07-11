import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Transaction.self,
                                      Category.self,
                                      Account.self,
                                      TransactionAdjustment.self,
                                      CategoryEstimate.self, configurations: .init(isStoredInMemoryOnly: false))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                MonthlyFilterView(viewModel: .init(modelContext: sharedModelContainer.mainContext))
                    .tabItem {
                        Label("Tracker", systemImage: "dollarsign.circle")
                    }
                
                DataManagementView()
                    .tabItem {
                        Label("Data", systemImage: "gear")
                    }
            }
        }
        .environment(\.modelContext, sharedModelContainer.mainContext)
    }
}

// Função auxiliar para criar o ModelContainer para previews
func previewModelContainer() -> ModelContainer? {
    do {
        let container = try ModelContainer(
            for:
                Transaction.self,
                Category.self,
                Account.self,
                TransactionAdjustment.self,
                CategoryEstimate.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        return container
    } catch {
        print("Failed to create preview container: \(error)")
        return nil
    }
}
