import SwiftUI
import SwiftData

struct MonthlyFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category] // Para o filtro de categorias
    
    @State private var selectedDate = Date()
    @State private var selectedType: TransactionTypeFilter = .all // Filtro de tipo
    @State private var selectedCategory: Category? = nil // Filtro de categoria
    
    // Enum para o filtro de tipo
    enum TransactionTypeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case income = "Income"
        case expense = "Expense"
        
        var id: String { rawValue }
    }
    
    private var filteredOccurrences: [(transaction: Transaction, date: Date, amount: Double)] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedDate)
        let month = components.month!
        let year = components.year!
        
        // Filtra as transações com base no mês e ano
        var occurrences = transactions.flatMap { transaction in
            transaction.occurrencesForMonth(month: month, year: year).map { (transaction, $0.date, $0.amount) }
        }
        
        // Aplica filtro de tipo
        occurrences = occurrences.filter { occurrence in
            switch selectedType {
            case .all:
                return true
            case .income:
                return occurrence.2 >= 0
            case .expense:
                return occurrence.2 < 0
            }
        }
        
        // Aplica filtro de categoria
        if let category = selectedCategory {
            occurrences = occurrences.filter { $0.0.category == category }
        }
        
        return occurrences
    }
    
    private var monthlyBalance: Double {
        filteredOccurrences.reduce(0) { $0 + $1.amount }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                MonthYearPicker(selectedDate: $selectedDate)
                
                // Filtros
                HStack(spacing: 20) {
                    // Filtro de Tipo
                    HStack(spacing: 8) {
                        FilterButton(title: "All", isSelected: selectedType == .all) {
                            selectedType = .all
                        }
                        FilterButton(title: "Income", isSelected: selectedType == .income) {
                            selectedType = .income
                        }
                        FilterButton(title: "Expense", isSelected: selectedType == .expense) {
                            selectedType = .expense
                        }
                    }
                    
                    Spacer()
                    
                    // Filtro de Categoria
                    Menu {
                        Button("All") { selectedCategory = nil }
                        ForEach(categories) { category in
                            Button(category.name) { selectedCategory = category }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCategory?.name ?? "Category")
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
                
                Text("Balance for \(monthYearString): \(monthlyBalance, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(monthlyBalance >= 0 ? .green : .red)
                    .padding()
                
                List(filteredOccurrences, id: \.date) { occurrence in
                    NavigationLink(destination: TransactionDetailView(transaction: occurrence.transaction)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(occurrence.transaction.title)
                                    .font(.headline)
                                Text(occurrence.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                if let category = occurrence.transaction.category {
                                    Text(category.name)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            Spacer()
                            Text("\(occurrence.amount, specifier: "%.2f")")
                                .foregroundStyle(occurrence.amount >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle("Monthly Balance")
        }
    }
}

#Preview {
    MonthlyFilterView()
        .modelContainer(for: [Transaction.self, Category.self, TransactionAdjustment.self], inMemory: true)
}

// Componente auxiliar para botões de filtro
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .blue : .gray)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(6)
        }
    }
}
