import SwiftUI

struct OnboardingView: View {
    @Environment(SupabaseService.self) private var supabase

    @State private var displayName = ""
    @State private var reunionDate = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var hasReunionDate = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    MascotView(pose: .happy, size: 120, animation: .breathe)
                        .padding(.top, Spacing.hero)

                    VStack(spacing: Spacing.sm) {
                        Text("Almost there!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.ink)

                        Text("Tell us a little about yourself")
                            .font(.romanticSub)
                            .foregroundStyle(Color.inkSoft)
                    }

                    // Display name
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("What should we call you?")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.ink)

                            TextField("Your name", text: $displayName)
                                .font(.system(size: 17))
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.md)
                                .background(Color.white.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.rose.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                    }

                    // Reunion date
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Toggle(isOn: $hasReunionDate) {
                                Text("Next reunion date")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.ink)
                            }
                            .tint(Color.rose)

                            if hasReunionDate {
                                DatePicker(
                                    "Reunion date",
                                    selection: $reunionDate,
                                    in: Date.now...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color.rose)
                            }
                        }
                    }

                    // Timezone (auto-detected)
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Your timezone")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.ink)

                                Text(TimeZone.current.identifier)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.sage)
                                .font(.system(size: 22))
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.roseDark)
                    }

                    Button("Continue") {
                        Task { await saveAndContinue() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    .padding(.top, Spacing.md)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 100)
            }
            .background(BackgroundGradient(style: .heart))
        }
    }

    private func saveAndContinue() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.updateProfile(
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                timezone: TimeZone.current.identifier
            )

            if hasReunionDate {
                try await supabase.updateReunionDate(reunionDate)
            }

            supabase.hasCompletedOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
