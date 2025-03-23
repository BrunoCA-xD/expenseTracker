import SwiftUI

// Componente auxiliar para botões de filtro
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .blue : .secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(6)
        }
    }
}

#Preview {
    
    FilterButton(title: "title", isSelected: true) { }
}
