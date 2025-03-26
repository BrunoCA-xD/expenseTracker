import SwiftUI
import SwiftData

struct AccountEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let account: Account
    
    @State private var name: String
    
    init(account: Account) {
        self.account = account
        self._name = State(initialValue: account.name)
    }
    
    var body: some View {
        Form {
            Section("Account Details") {
                TextField("Name", text: $name)
            }
        }
        .navigationTitle("Edit Account")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    account.name = name
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}
