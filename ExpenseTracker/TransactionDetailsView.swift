import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TransactionDetailViewModel
    
    init(transaction: Transaction, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TransactionDetailViewModel(transaction: transaction, modelContext: modelContext))
    }
    
    var body: some View {
        Form {
            Section("Detalhes") {
                Text("Título: \(viewModel.transaction.title)")
                Text("Valor: \(viewModel.transaction.initialBaseAmount, specifier: "%.2f")")
                Text("Data: \(viewModel.transaction.date, style: .date)")
                if viewModel.transaction.isRecurring {
                    Text("Recorrente: Sim (\(viewModel.transaction.recurrenceType.description))")
                } else {
                    Text("Recorrente: Não")
                }
                if let installments = viewModel.transaction.numberOfInstallments {
                    Text("Número de parcelas: \(installments)")
                }
                if let category = viewModel.transaction.category {
                    Text("Categoria: \(category.name)")
                    if let estimate = viewModel.estimateForMonth(date: viewModel.transaction.date) {
                        Text("Estimativa mensal: \(estimate, specifier: "%.2f")")
                    }
                }
                if let account = viewModel.transaction.account {
                    Text("Conta: \(account.name)")
                }
            }
            
            if viewModel.transaction.isRecurring {
                Section("Opções de recorrência") {
                    Toggle("Definir fim", isOn: $viewModel.hasEndDate)
                    if viewModel.hasEndDate {
                        DatePicker("Data", selection: $viewModel.endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        Button("Salvar data final") {
                            viewModel.saveEndDate()
                        }
                    }
                }
                
                Section("Ajustes de valor") {
                    if viewModel.transaction.adjustments.isEmpty {
                        Text("Nenhum ajuste ainda.")
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(viewModel.transaction.adjustments.sorted { $0.startDate < $1.startDate }) { adjustment in
                            HStack {
                                Text(adjustment.startDate, style: .date)
                                Spacer()
                                Text("\(adjustment.amount, specifier: "%.2f") \(adjustment.isPermanent ? "(Fixo)" : "(Dessa vez)")")
                            }
                        }
                        .onDelete(perform: viewModel.deleteAdjustment)
                    }
                }
                Section {
                    Button("Adicionar Ajuste") {
                        viewModel.showingAddAdjustment = true
                    }
                }
            }
            Section {
                Button("Deletar Transação") {
                    viewModel.showingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Detalhes da transação")
        .sheet(isPresented: $viewModel.showingAddAdjustment) {
            AddAdjustmentView(transaction: viewModel.transaction)
        }
        .confirmationDialog(
            "Deletar Transação",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Deletar", role: .destructive) {
                viewModel.deleteTransaction()
                dismiss()
            }
        } message: {
            Text(viewModel.transaction.isRecurring ?
                 "Tem certeza que quer deletar '\(viewModel.transaction.title)'? Essa transação é recorrente e deletar irá remover ocorrências passadas e futuras." :
                 "Tem certeza que quer deletar '\(viewModel.transaction.title)'?")
        }
    }
}

#Preview {
    if let container = previewModelContainer() {
        let transaction = Transaction(title: "title", initialBaseAmount: 10, date: Date(), isRecurring: true, recurrenceType: .monthly, numberOfInstallments: 2, endDate: nil, category: nil, account: nil)
        let viewModel = MonthlyFilterViewModel(modelContext: container.mainContext)
        TransactionDetailView(transaction: transaction, modelContext: container.mainContext)
                    .modelContext(container.mainContext)
    } else {
        Text("Failed to create preview: ModelContainer initialization failed")
    }
}
