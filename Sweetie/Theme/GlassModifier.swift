import SwiftUI

struct SweetieGlass: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .shadow(color: Color.ink.opacity(0.08), radius: 12, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.30), lineWidth: 0.5)
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .shadow(color: Color.ink.opacity(0.08), radius: 12, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.30), lineWidth: 0.5)
                )
        }
    }
}

extension View {
    func sweetieGlass(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(SweetieGlass(cornerRadius: cornerRadius))
    }
}
