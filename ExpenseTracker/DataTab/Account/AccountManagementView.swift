import SwiftUI
import SwiftData

struct AccountManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    
    @State private var showingAddAccount = false
    
    var body: some View {
        List {
            Section(header: Text("Categories")) {
                ForEach(accounts) { account in
                    NavigationLink(destination: AccountEditView(account: account)) {
                        Text(account.name)
                                .font(.headline)
                            
                    }
                }
                .onDelete(perform: deleteAccount)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus") { showingAddAccount = true }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView()
        }
    }
    
    
    private func deleteAccount(at offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            modelContext.delete(account)
        }
        try? modelContext.save()
    }
}
