import SwiftUI
import SwiftData

struct MonthlyFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MonthlyFilterViewModel
    
    init(viewModel: MonthlyFilterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                HStack (alignment: .bottom) {
                    Button {
                        viewModel.previousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Inicio")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Fim")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Button {
                        viewModel.nextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Menu {
                        Button("Todos") { viewModel.selectedType = nil }
                        Button("Entradas") { viewModel.selectedType = .income }
                        Button("Saídas") { viewModel.selectedType = .expense }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedType?.rawValue ?? "Tipo" )
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                    
                    Menu {
                        Button("Todas") { viewModel.selectedCategory = nil }
                        ForEach(viewModel.categories) { category in
                            Button(category.name) { viewModel.selectedCategory = category }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedCategory?.name ?? "Categoria")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                    
                    Menu {
                        Button("Todas") { viewModel.selectedAccount = nil }
                        ForEach(viewModel.accounts) { account in
                            Button(account.name) { viewModel.selectedAccount = account }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedAccount?.name ?? "Conta")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Saldo Total: \(viewModel.totalBalance, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(viewModel.totalBalance >= 0 ? .green : .red)
                    Text("Saldo Real: \(viewModel.realBalance, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Text("Saldo das estimativas: \(viewModel.estimatedBalance, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                                
                List(viewModel.filteredOccurrences, id: \.date) { occurrence in
                    NavigationLink(destination: TransactionDetailView(transaction: occurrence.transaction)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(occurrence.transaction.title)
                                        .font(.headline)
                                    if occurrence.transaction.isRecurring {
                                        Image(systemName: "arrow.2.circlepath")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    if let installmentInfo = occurrence.installmentInfo {
                                        Text(installmentInfo)
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                            .padding(.horizontal, 4)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                Text(occurrence.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                if let category = occurrence.transaction.category {
                                    Text(category.name)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    if let estimate = category.estimates.first(where: { Calendar.current.isDate($0.date, equalTo: occurrence.date, toGranularity: .month) }) {
                                        Text("Estimativa: \(estimate.amount, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                if let account = occurrence.transaction.account {
                                    Text(account.name)
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                }
                            }
                            Spacer()
                            Text("\(occurrence.amount, specifier: "%.2f")")
                                .foregroundStyle(occurrence.amount >= 0 ? .green : .red)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Visão Mensal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.showingAddTransaction = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTransaction, onDismiss: {
                viewModel.fetchData()
            }) {
                AddTransactionView()
            }
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}

// Função auxiliar para criar o ModelContainer para previews
private func previewModelContainer() -> ModelContainer? {
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

#Preview {
    if let container = previewModelContainer() {
        let viewModel = MonthlyFilterViewModel(modelContext: container.mainContext)
        MonthlyFilterView(viewModel: viewModel)
                    .modelContext(container.mainContext)
    } else {
        Text("Failed to create preview: ModelContainer initialization failed")
    }
}
