import SwiftUI

struct DataManagementView: View {
    @State private var defaultDay: Int = UserDefaults.standard.integer(forKey: "defaultDay") > 0 ? UserDefaults.standard.integer(forKey: "defaultDay") : 12
    
    var body: some View {
        NavigationStack {
            Form {
                NavigationLink("Categories") {
                    CategoryManagementView()
                }
                NavigationLink("Accounts") {
                    AccountManagementView()
                }
                Section(header: Text("Period Settings")) {
                    Stepper(value: $defaultDay, in: 1...31, step: 1) {
                        Text("Default Day: \(defaultDay)")
                    }
                    .onChange(of: defaultDay) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "defaultDay")
                    }
                }
            }
            .navigationTitle("Data Management")
        }
    }
}

#Preview {
    DataManagementView()
}
