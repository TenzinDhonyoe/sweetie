import SwiftUI

extension Font {
    static let heroDisplay = Font.custom("PlayfairDisplay-Bold", size: 48)
    static let romantic = Font.custom("PlayfairDisplay-Regular", size: 20)
    static let romanticSub = Font.custom("PlayfairDisplay-Italic", size: 17)
    static let romanticSmall = Font.custom("PlayfairDisplay-Regular", size: 15)
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.inkFaint)
            .tracking(0.5)
    }
}

extension View {
    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }
}
