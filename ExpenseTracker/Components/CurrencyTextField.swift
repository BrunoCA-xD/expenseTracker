//
//  CurrencyTextField.swift
//  ExpenseTracker
//
//  Created by Bruno Ambrosio on 23/03/25.
//

import SwiftUI

struct CurrencyTextField: View {
    @Binding var value: Double // Valor numérico real, pode ser positivo ou negativo
    @State private var text: String // Texto formatado exibido
    
    // Formatter para moeda
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.negativePrefix = "R$ -" // Garante formatação negativa
        return formatter
    }()
    
    init(value: Binding<Double>) {
        self._value = value
        let initialValue = value.wrappedValue
        self._text = State(initialValue: initialValue != 0 ? currencyFormatter.string(from: NSNumber(value: initialValue)) ?? "" : "")
    }
    
    var body: some View {
        TextField("Amount (R$)", text: $text)
            .keyboardType(.decimalPad)
            .onChange(of: text) { _, newValue in
                updateValue(from: newValue)
            }
    }
    
    private func updateValue(from text: String) {
        // Filtra apenas dígitos e sinal negativo (se presente)
        let isNegative = text.contains("-")
        let digits = text.filter { $0.isNumber }
        
        // Converte para centavos
        if let rawValue = Double(digits) {
            let formattedValue = rawValue / 100.0
            value = isNegative ? -formattedValue : formattedValue
            if let formattedString = currencyFormatter.string(from: NSNumber(value: value)) {
                self.text = formattedString
            } else {
                self.text = digits.isEmpty ? "" : (isNegative ? "R$ -\(digits)" : "R$ \(digits)")
            }
        } else {
            value = 0.0
            self.text = ""
        }
    }
}

#Preview {
    CurrencyTextField(value: .constant(-1234.56))
}
