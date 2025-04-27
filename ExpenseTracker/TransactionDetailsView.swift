import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let transaction: Transaction
    @State private var showingAddAdjustment = false
    @State private var hasEndDate: Bool // Reflete se há endDate
    @State private var endDate: Date
    @State private var showingDeleteConfirmation = false
    
    init(transaction: Transaction) {
        self.transaction = transaction
        self._hasEndDate = State(initialValue: transaction.endDate != nil)
        self._endDate = State(initialValue: transaction.endDate ?? Date())
    }
    
    var body: some View {
        Form {
            Section("Detalhes") {
                Text("Título: \(transaction.title)")
                Text("Valor: \(transaction.initialBaseAmount, specifier: "%.2f")")
                Text("Data: \(transaction.date, style: .date)")
                Text("Recorrente: \(transaction.isRecurring ? "Sim (\(transaction.recurrenceType.rawValue))" : "Não")")
                if let installments = transaction.numberOfInstallments {
                    Text("Número de parcelas: \(installments)")
                }
                if let category = transaction.category {
                    Text("Categoria: \(category.name)")
                    if let estimate = category.estimateForMonth(month: Calendar.current.component(.month, from: transaction.date), year: Calendar.current.component(.year, from: transaction.date)) {
                        Text("Estimativa mensal: \(estimate, specifier: "%.2f")")
                    }
                }
                if let account = transaction.account {
                    Text("Conta: \(account.name)")
                }
            }
            
            if transaction.isRecurring {
                Section("Opções de recorrência") {
                    Toggle("Definir fim", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Data", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    Button("Salvar data final") {
                        transaction.endDate = hasEndDate ? endDate : nil
                        try? modelContext.save()
                    }
                }
                
                Section("Ajustes de valor") {
                    if transaction.adjustments.isEmpty {
                        Text("Nenhum ajuste ainda.")
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(transaction.adjustments.sorted { $0.startDate < $1.startDate }) { adjustment in
                            HStack {
                                Text(adjustment.startDate, style: .date)
                                Spacer()
                                Text("\(adjustment.amount, specifier: "%.2f") \(adjustment.isPermanent ? "(Fixo)" : "(Dessa vez)")")
                            }
                        }
                        .onDelete(perform: deleteAdjustment)
                    }
                }
                Section {
                    Button("Adicionar Ajuste") {
                        showingAddAdjustment = true
                    }
                }
            }
            Section {
                Button("Deletar Transação") {
                    showingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Detalhes da transação")
        .sheet(isPresented: $showingAddAdjustment) {
            AddAdjustmentView(transaction: transaction)
        }
        .confirmationDialog(
            "Deletar Transação",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Deletar", role: .destructive) {
                modelContext.delete(transaction)
                try? modelContext.save()
                dismiss() // Fecha a view após o feedback
            }
        } message: {
            Text(transaction.isRecurring ?
                 "Tem certeza que quer deletar '\(transaction.title)'? Essa transação é recorrente e deletar irá remover ocorrências passadas e futuras." : "Tem certeza que quer deletar '\(transaction.title)'?")
        }
        
        
    }
    
    private func deleteAdjustment(at offsets: IndexSet) {
        for index in offsets {
            let adjustment = transaction.adjustments.sorted { $0.startDate < $1.startDate }[index]
            modelContext.delete(adjustment)
        }
        try? modelContext.save()
    }
}
