import SwiftUI

struct SweetieGlass: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .glassEffect()
            )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.ink.opacity(0.06), radius: 8, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
        }
    }
}

extension View {
    func sweetieGlass(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(SweetieGlass(cornerRadius: cornerRadius))
    }
}
