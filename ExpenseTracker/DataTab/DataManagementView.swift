import SwiftUI

struct DataManagementView: View {
    var body: some View {
        NavigationStack {
            Form {
                NavigationLink("Categories") {
                    CategoryManagementView()
                }
                NavigationLink("Accounts") {
                    AccountManagementView()
                }
            }
            .navigationTitle("Data Management")
        }
    }
}

#Preview {
    DataManagementView()
}
