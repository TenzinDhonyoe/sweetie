import SwiftUI

struct BackgroundGradient: View {
    var style: GradientStyle = .default

    enum GradientStyle {
        case `default`
        case heart
        case photo
        case notes
    }

    var body: some View {
        switch style {
        case .default:
            LinearGradient(
                colors: [.cream, .blush, .rosePale],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        case .heart:
            LinearGradient(
                colors: [.cream, .rosePale, .roseLight],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        case .photo:
            LinearGradient(
                colors: [.cream, .blush],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        case .notes:
            LinearGradient(
                colors: [.cream, Color(red: 0.973, green: 0.929, blue: 0.890)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        }
    }
}
