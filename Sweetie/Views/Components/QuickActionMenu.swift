import SwiftUI

struct TapPreset {
    let emoji: String
    let label: String
    let pattern: String
    let haptic: () -> Void
}

struct QuickActionMenu: View {
    @Environment(\.dismiss) private var dismiss

    var onSendPreset: (_ emoji: String, _ pattern: String) -> Void = { _, _ in }

    private let presets: [TapPreset] = [
        TapPreset(emoji: "💕", label: "I love you", pattern: "love", haptic: HapticService.tripleQuick),
        TapPreset(emoji: "🤗", label: "Hug", pattern: "hug", haptic: HapticService.longHug),
        TapPreset(emoji: "😘", label: "Kiss", pattern: "kiss", haptic: HapticService.doubleKiss),
        TapPreset(emoji: "🌙", label: "Goodnight", pattern: "goodnight", haptic: HapticService.gentleNight),
        TapPreset(emoji: "☀️", label: "Good morning", pattern: "morning", haptic: HapticService.morningRise),
    ]

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Send with love")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ink)
                .padding(.top, Spacing.xxl)

            ForEach(presets, id: \.pattern) { preset in
                presetRow(preset)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .background(BackgroundGradient())
        .presentationDetents([.medium])
    }

    private func presetRow(_ preset: TapPreset) -> some View {
        Button {
            preset.haptic()
            onSendPreset(preset.emoji, preset.pattern)
            dismiss()
        } label: {
            GlassCard {
                HStack(spacing: Spacing.md) {
                    Text(preset.emoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)

                    Text(preset.label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.ink)

                    Spacer()
                }
            }
        }
    }
}
