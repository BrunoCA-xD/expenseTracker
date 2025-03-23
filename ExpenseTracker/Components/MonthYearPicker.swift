import SwiftUI
import SwiftData

// Componente personalizado para selecionar mês e ano
struct MonthYearPicker: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let months = DateFormatter().monthSymbols
    
    var body: some View {
        HStack(spacing: 12) {
            // Navegação de mês
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
            
            Text(monthYearString)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(minWidth: 150)
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
