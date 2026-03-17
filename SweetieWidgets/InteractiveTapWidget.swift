import WidgetKit
import SwiftUI

struct InteractiveTapEntry: TimelineEntry {
    let date: Date
    let lastTap: SharedTapData?
    let hasCredentials: Bool
}

struct InteractiveTapProvider: TimelineProvider {
    func placeholder(in context: Context) -> InteractiveTapEntry {
        InteractiveTapEntry(date: .now, lastTap: nil, hasCredentials: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (InteractiveTapEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InteractiveTapEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> InteractiveTapEntry {
        let manager = SharedDataManager.shared
        let hasCredentials = manager.loadAuthToken() != nil && manager.loadCoupleId() != nil
        return InteractiveTapEntry(
            date: .now,
            lastTap: manager.loadLastTap(),
            hasCredentials: hasCredentials
        )
    }
}

// MARK: - Small Widget View

struct InteractiveTapSmallView: View {
    let entry: InteractiveTapEntry

    var body: some View {
        if entry.hasCredentials {
            VStack(spacing: Spacing.sm) {
                Spacer()

                // Interactive tap button
                Button(intent: SendTapIntent()) {
                    Text("💕")
                        .font(.system(size: 40))
                }
                .buttonStyle(.plain)

                Text("Tap to send love")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)

                if let tap = entry.lastTap {
                    Text("Last: \(tap.timestamp, style: .relative)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkFaint)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: Spacing.sm) {
                Image("mascot-wave")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 32, height: 32)
                Text("Open Sweetie\nto connect")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Widget Definition

struct InteractiveTapWidget: Widget {
    let kind = "InteractiveTapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InteractiveTapProvider()) { entry in
            InteractiveTapSmallView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.cream, Color.rosePale],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Quick Tap")
        .description("Send love without even opening the app")
        .supportedFamilies([.systemSmall])
    }
}
