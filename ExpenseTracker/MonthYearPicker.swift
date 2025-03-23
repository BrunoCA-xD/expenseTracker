import SwiftUI
import SwiftData

// Componente personalizado para selecionar mês e ano
struct MonthYearPicker: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let months = DateFormatter().monthSymbols!
    private let years = Array((Calendar.current.component(.year, from: Date()) - 10)...(Calendar.current.component(.year, from: Date()) + 10))
    
    var body: some View {
        HStack(spacing: 10) {
            Picker("Month", selection: Binding(
                get: { calendar.component(.month, from: selectedDate) },
                set: { newMonth in
                    updateDate(month: newMonth, year: calendar.component(.year, from: selectedDate))
                }
            )) {
                ForEach(1...12, id: \.self) { month in
                    Text(months[month - 1]).tag(month)
                }
            }
            .pickerStyle(.menu) // Estilo menu para legibilidade
            
            Picker("Year", selection: Binding(
                get: { calendar.component(.year, from: selectedDate) },
                set: { newYear in
                    updateDate(month: calendar.component(.month, from: selectedDate), year: newYear)
                }
            )) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func updateDate(month: Int, year: Int) {
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1 // Fixa o dia como 1 para consistência
        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
        }
    }
}
