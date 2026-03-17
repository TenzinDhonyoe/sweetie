import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var currentPage: Int = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            gradient: .default,
            pose: .wave,
            animation: .wiggle,
            title: "Two hearts,\none connection",
            subtitle: "Sweetie keeps you close when the miles don't."
        ),
        WelcomePage(
            gradient: .heart,
            pose: .excited,
            animation: .bounce,
            title: "A tap that\ntravels the world",
            subtitle: "One touch sends a heartbeat across any distance."
        ),
        WelcomePage(
            gradient: .default,
            pose: .peek,
            animation: .none,
            title: "Moments that\narrive like gifts",
            subtitle: "Send a photo and it appears on their screen right away."
        ),
        WelcomePage(
            gradient: .notes,
            pose: .hug,
            animation: .breathe,
            title: "Counting down\nto together",
            subtitle: "Love notes, daily questions, and a reunion that gets closer every second."
        )
    ]

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    WelcomePageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                Spacer()

                pageIndicator

                actionButtons
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.hero)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.rose : Color.roseLight)
                    .frame(width: 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
        .padding(.bottom, Spacing.xxl)
    }

    private var actionButtons: some View {
        VStack(spacing: Spacing.lg) {
            if currentPage < pages.count - 1 {
                Button("Continue") {
                    withAnimation(.spring(duration: 0.3)) {
                        currentPage += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Skip") {
                    hasOnboarded = true
                }
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)
            } else {
                Button("Let's begin") {
                    hasOnboarded = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

private struct WelcomePage {
    let gradient: BackgroundGradient.GradientStyle
    let pose: MascotView.Pose
    let animation: MascotView.MascotAnimation
    let title: String
    let subtitle: String
}

private struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        ZStack {
            BackgroundGradient(style: page.gradient)

            VStack(spacing: Spacing.xxxl) {
                Spacer()

                MascotView(pose: page.pose, size: 120, animation: page.animation)

                VStack(spacing: Spacing.lg) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text(page.subtitle)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
}
