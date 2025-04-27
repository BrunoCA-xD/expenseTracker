import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddTransactionViewModel
    
    init(viewModel: AddTransactionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes") {
                    TextField("Título", text: $viewModel.title)
                    CurrencyTextField(value: $viewModel.amount)
                    HStack {
                        Text("Tipo")
                        Spacer()
                        Picker("Tipo", selection: $viewModel.isIncome) {
                            Text("Saída").tag(false)
                            Text("Entrada").tag(true)
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                    DatePicker("Data", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                Section("Recorrência") {
                    Toggle("É recorrente", isOn: $viewModel.isRecurring)
                    if viewModel.isRecurring {
                        Picker("Frequência", selection: $viewModel.recurrenceType) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                Text(type.description.capitalized).tag(type)
                            }
                        }
                        if viewModel.recurrenceType == .monthly {
                            TextField("Nº de parcelas (caso parcelamento) ", value: $viewModel.numberOfInstallments, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                Section("Categoria") {
                    Picker("Categoria", selection: $viewModel.selectedCategory) {
                        Text("Nenhuma").tag(Category?.none)
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    }
                    Button("Nova categoria") {
                        viewModel.showingAddCategory = true
                    }
                    if viewModel.categories.isEmpty {
                        Text("Sem categorias disponíveis.")
                            .foregroundStyle(.gray)
                    }
                }
                
                Section("Conta") {
                    Picker("Conta", selection: $viewModel.selectedAccount) {
                        Text("Nenhuma").tag(Account?.none)
                        ForEach(viewModel.accounts) { account in
                            Text(account.name).tag(Optional(account))
                        }
                    }
                    Button("Nova Conta") {
                        viewModel.showingAddAccount = true
                    }
                    if viewModel.accounts.isEmpty {
                        Text("Sem contas disponíveis.")
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("Adicionar Transação")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        viewModel.saveTransaction()
                        dismiss()
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .sheet(isPresented: $viewModel.showingAddCategory) {
                AddCategoryView(date: viewModel.date) { newCategory in
                    viewModel.selectedCategory = newCategory
                }
                .onDisappear {
                    viewModel.fetchData()
                }
            }
            .sheet(isPresented: $viewModel.showingAddAccount) {
                AddAccountView() { newAccount in
                    viewModel.selectedAccount = newAccount
                }
                .onDisappear {
                    viewModel.fetchData()
                }
            }
        }
    }
}

#Preview {
    if let container = previewModelContainer() {
        let viewModel = AddTransactionViewModel(modelContext: container.mainContext)
        AddTransactionView(viewModel: viewModel)
            .modelContext(container.mainContext)
    } else {
        Text("Failed to create preview#")
    }
}
