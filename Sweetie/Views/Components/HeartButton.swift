import SwiftUI

struct HeartButton: View {
    var onTap: () -> Void = {}
    var onLongPress: () -> Void = {}
    @Binding var receivedTap: Bool

    @State private var isPressed = false
    @State private var showRipple = false
    @State private var bounceScale: CGFloat = 1.0
    @State private var floatingText: String?
    @State private var floatingOffset: CGFloat = 0
    @State private var floatingOpacity: Double = 1
    @State private var tapSent = false

    var body: some View {
        ZStack {
            if showRipple {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.rose.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 60 + CGFloat(i) * 20, height: 60 + CGFloat(i) * 20)
                        .scaleEffect(showRipple ? 1.5 : 1)
                        .opacity(showRipple ? 0 : 1)
                        .animation(
                            .spring(duration: 0.6).delay(Double(i) * 0.1),
                            value: showRipple
                        )
                }
            }

            // Floating "+1 💕" indicator
            if let text = floatingText {
                Text(text)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.rose)
                    .offset(y: floatingOffset)
                    .opacity(floatingOpacity)
            }

            Circle()
                .fill(Color.rose)
                .frame(width: 60, height: 60)
                .shadow(color: .rose.opacity(0.3), radius: 8, y: 4)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                )
                .scaleEffect(isPressed ? 0.88 : bounceScale)
                .onTapGesture {
                    // Press down
                    withAnimation(.spring(duration: 0.15)) {
                        isPressed = true
                    }
                    HapticService.heavyTap()

                    // Release with overshoot bounce
                    withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                        isPressed = false
                        bounceScale = 1.15
                        showRipple = true
                    }

                    // Settle back to 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                            bounceScale = 1.0
                        }
                    }

                    HapticService.success()
                    SoundService.play(.pop)
                    tapSent.toggle()
                    onTap()
                    showFloatingText("+1 💕")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showRipple = false
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    HapticService.heavyTap()
                    onLongPress()
                }
                .sensoryFeedback(.impact(weight: .heavy), trigger: tapSent)
        }
        .onChange(of: receivedTap) { _, newValue in
            if newValue {
                // Receive pulse animation
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) {
                    bounceScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                        bounceScale = 1.0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    receivedTap = false
                }
            }
        }
    }

    private func showFloatingText(_ text: String) {
        floatingText = text
        floatingOffset = 0
        floatingOpacity = 1

        withAnimation(.easeOut(duration: 0.8)) {
            floatingOffset = -60
            floatingOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            floatingText = nil
        }
    }
}
