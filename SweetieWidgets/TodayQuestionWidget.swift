import WidgetKit
import SwiftUI

struct TodayQuestionEntry: TimelineEntry {
    let date: Date
    let question: SharedQuestionData?
}

struct TodayQuestionProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayQuestionEntry {
        TodayQuestionEntry(
            date: .now,
            question: SharedQuestionData(
                questionText: "What's your favorite memory together?",
                myAnswer: nil,
                partnerAnswer: nil,
                isUnlocked: false
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayQuestionEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayQuestionEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh at midnight (new question each day) or in 1 hour
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let refreshDate = min(nextMidnight, nextHour)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func loadEntry() -> TodayQuestionEntry {
        TodayQuestionEntry(
            date: .now,
            question: SharedDataManager.shared.loadTodayQuestion()
        )
    }
}

// MARK: - Medium Widget View

struct TodayQuestionMediumView: View {
    let entry: TodayQuestionEntry

    var body: some View {
        if let question = entry.question {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lavender)
                    Text("Today's Question")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.inkFaint)
                    Spacer()
                }

                Text(question.questionText)
                    .font(.custom("PlayfairDisplay-Italic", size: 15))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)

                Spacer(minLength: 0)

                // Answer status
                answerStatus(question)
            }
            .padding(Spacing.md)
        } else {
            VStack(spacing: Spacing.sm) {
                Image("mascot-peek")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 32, height: 32)
                Text("Open Sweetie to start")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func answerStatus(_ question: SharedQuestionData) -> some View {
        if question.isUnlocked {
            // Both answered — show both answers
            HStack(spacing: Spacing.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.rose)
                Text("Both answered")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.rose)
            }
        } else if question.myAnswer != nil && question.partnerAnswer == nil {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.sage)
                Text("Waiting for partner...")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
            }
        } else if question.myAnswer == nil && question.partnerAnswer != nil {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gold)
                Text("Your turn to answer!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.gold)
            }
        } else {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkFaint)
                Text("Tap to answer together")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkFaint)
            }
        }
    }
}

// MARK: - Widget Definition

struct TodayQuestionWidget: Widget {
    let kind = "TodayQuestionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayQuestionProvider()) { entry in
            TodayQuestionMediumView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.cream, Color.blush],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .widgetURL(URL(string: "sweetie://home"))
        }
        .configurationDisplayName("Today's Question")
        .description("A new question every day to grow closer")
        .supportedFamilies([.systemMedium])
    }
}
