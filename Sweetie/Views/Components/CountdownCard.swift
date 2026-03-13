import SwiftUI

struct CountdownCard: View {
    var reunionDate: Date?

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GlassCard {
            VStack(spacing: Spacing.sm) {
                if let reunionDate {
                    let components = Calendar.current.dateComponents(
                        [.day, .hour, .minute, .second],
                        from: now,
                        to: reunionDate
                    )

                    VStack(spacing: 2) {
                        Text("\(max(0, components.day ?? 0))")
                            .font(.countdownHero)
                            .foregroundStyle(Color.gold)
                            .contentTransition(.numericText())

                        Text("days")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkFaint)
                    }

                    HStack(spacing: Spacing.lg) {
                        timeUnit(value: max(0, components.hour ?? 0), label: "hrs")
                        timeUnit(value: max(0, components.minute ?? 0), label: "min")
                        timeUnit(value: max(0, components.second ?? 0), label: "sec")
                    }

                    Text("until I hold you again")
                        .font(.romanticSub)
                        .foregroundStyle(Color.inkSoft)
                        .padding(.top, Spacing.xs)
                } else {
                    Text("Set a reunion date")
                        .font(.romantic)
                        .foregroundStyle(Color.inkSoft)

                    Text("in Settings")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkFaint)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onReceive(timer) { tick in
            withAnimation(.snappy) {
                now = tick
            }
        }
    }

    private func timeUnit(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.inkFaint)
        }
    }
}
