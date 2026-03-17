import SwiftUI

struct MascotView: View {
    enum Pose: String {
        case `default` = "mascot-default"
        case excited = "mascot-excited"
        case happy = "mascot-happy"
        case hug = "mascot-hug"
        case love = "mascot-love"
        case peek = "mascot-peek"
        case sleep = "mascot-sleep"
        case wave = "mascot-wave"
    }

    enum MascotAnimation {
        case breathe
        case bounce
        case wiggle
        case none
    }

    let pose: Pose
    var size: CGFloat = 80
    var animation: MascotAnimation = .breathe

    @State private var animating = false

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .modifier(MascotAnimationModifier(style: animation, animating: animating))
            .onAppear {
                guard animation != .none else { return }
                withAnimation(.spring(duration: animationDuration, bounce: 0.1).repeatForever(autoreverses: true)) {
                    animating = true
                }
            }
    }

    private var animationDuration: Double {
        switch animation {
        case .breathe: 2.0
        case .bounce: 1.0
        case .wiggle: 1.5
        case .none: 0
        }
    }
}

private struct MascotAnimationModifier: ViewModifier {
    let style: MascotView.MascotAnimation
    let animating: Bool

    func body(content: Content) -> some View {
        switch style {
        case .breathe:
            content.scaleEffect(animating ? 1.03 : 0.97)
        case .bounce:
            content.offset(y: animating ? -8 : 0)
        case .wiggle:
            content.rotationEffect(.degrees(animating ? 3 : -3))
        case .none:
            content
        }
    }
}
