import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var newAccountName = ""
    let onAccountAdded: (Account) -> Void // Callback para retornar a nova conta
    
    init(onAccountAdded: @escaping (Account) -> Void = { _ in }) {
        self.onAccountAdded = onAccountAdded
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Account Name", text: $newAccountName)
            }
            .navigationTitle("New Account")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAccount()
                        dismiss()
                    }
                    .disabled(newAccountName.isEmpty)
                }
            }
        }
    }
    
    private func saveAccount() {
        let newAccount = Account(name: newAccountName)
        modelContext.insert(newAccount)
        try? modelContext.save()
        onAccountAdded(newAccount) // Retorna a nova conta
    }
}
