import SwiftUI

struct TodayQuestionView: View {
    let question: DailyQuestion
    let userId: String?
    let isPartner1: Bool
    let partnerName: String
    var onSubmit: (String) -> Void

    @State private var myAnswerText = ""
    @State private var hasSubmitted = false
    @State private var showReveal = false
    @State private var showMascot = false

    private var myExistingAnswer: String? {
        isPartner1 ? question.partner1Answer : question.partner2Answer
    }

    private var partnerExistingAnswer: String? {
        isPartner1 ? question.partner2Answer : question.partner1Answer
    }

    private var bothAnswered: Bool {
        question.partner1Answer != nil && question.partner2Answer != nil
    }

    private var isUnlocked: Bool {
        question.unlockedAt != nil
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Question
            GlassCard {
                VStack(spacing: Spacing.md) {
                    Text(question.questionText)
                        .font(.romantic)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)

                    Text("Day \(question.dayNumber) of 10")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkFaint)
                }
                .frame(maxWidth: .infinity)
            }

            // Answer area
            if myExistingAnswer != nil || hasSubmitted {
                lockedAnswerSection
            } else {
                answerInputSection
            }

            // Reveal
            if isUnlocked && bothAnswered {
                revealedAnswers
            }

            // Mascot celebration
            if showMascot {
                MascotView(pose: .excited, size: 64, animation: .bounce)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var answerInputSection: some View {
        VStack(spacing: Spacing.md) {
            TextEditor(text: $myAnswerText)
                .font(.romantic)
                .foregroundStyle(Color.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(Spacing.lg)
                .sweetieGlass(cornerRadius: 16)

            Button("Lock my answer") {
                guard !myAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                hasSubmitted = true
                HapticService.tap()
                onSubmit(myAnswerText)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var lockedAnswerSection: some View {
        VStack(spacing: Spacing.md) {
            // My answer locked
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Your answer is locked")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.rose)
                        Text("✨")
                    }
                    Text(myExistingAnswer ?? myAnswerText)
                        .font(.romanticSmall)
                        .foregroundStyle(Color.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Partner's locked card
            if !isUnlocked {
                if partnerExistingAnswer != nil {
                    // Both answered but not yet unlocked — trigger reveal
                    GlassCard {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundStyle(Color.rose)
                            Text("Both answered! Revealing...")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.ink)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onAppear {
                        HapticService.success()
                        withAnimation(.spring(duration: 0.5).delay(0.3)) {
                            showMascot = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showMascot = false }
                        }
                    }
                } else {
                    // Waiting for partner
                    GlassCard {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.inkFaint)
                            Text("\(partnerName)'s answer")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.inkSoft)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    MascotView(pose: .wave, size: 56, animation: .wiggle)
                    Text("Waiting for their answer...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkFaint)
                }
            }
        }
    }

    private var revealedAnswers: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("You")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.rose)
                    Text(myExistingAnswer ?? "")
                        .font(.romanticSmall)
                        .foregroundStyle(Color.ink)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(partnerName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.lavender)
                    Text(partnerExistingAnswer ?? "")
                        .font(.romanticSmall)
                        .foregroundStyle(Color.ink)
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}
