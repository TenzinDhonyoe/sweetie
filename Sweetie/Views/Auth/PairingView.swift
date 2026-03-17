import SwiftUI
import os

private let logger = Logger(subsystem: "com.sweetie.together", category: "Pairing")

struct PairingView: View {
    @Environment(SupabaseService.self) private var supabase

    enum PairingState {
        case choosingRole
        case waitingForPartner(code: String)
        case celebration
    }

    @State private var pairingState: PairingState = .choosingRole
    @State private var inviteCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var dotCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    switch pairingState {
                    case .choosingRole:
                        choosingRoleContent
                    case .waitingForPartner(let code):
                        waitingContent(code: code)
                    case .celebration:
                        celebrationContent
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 100)
            }
            .background(BackgroundGradient())
        }
        .onChange(of: supabase.authState) { _, newState in
            if newState == .paired {
                withAnimation(.gentle) {
                    pairingState = .celebration
                }
                HapticService.success()
            }
        }
    }

    // MARK: - Choosing Role

    private var choosingRoleContent: some View {
        Group {
            MascotView(pose: .wave, size: 100, animation: .wiggle)
                .padding(.top, Spacing.hero)

            Text("Find your partner")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.ink)

            // Card 1: Start a couple
            GlassCard {
                VStack(spacing: Spacing.lg) {
                    Text("Start a couple")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.ink)

                    Text("Generate an invite code to share with your partner")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSoft)
                        .multilineTextAlignment(.center)

                    Button("Create Invite Code") {
                        Task { await createCouple() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading)
                }
                .frame(maxWidth: .infinity)
            }

            // Card 2: Join your partner
            GlassCard {
                VStack(spacing: Spacing.lg) {
                    Text("Join your partner")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.ink)

                    Text("Enter the code your partner shared with you")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSoft)
                        .multilineTextAlignment(.center)

                    TextField("Invite code", text: $inviteCode)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.rose.opacity(0.15), lineWidth: 0.5)
                        )

                    Button("Join") {
                        Task { await joinCouple() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading || inviteCode.isEmpty)
                }
                .frame(maxWidth: .infinity)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roseDark)
            }
        }
    }

    // MARK: - Waiting for Partner

    private func waitingContent(code: String) -> some View {
        Group {
            Spacer()
                .frame(height: Spacing.hero)

            MascotView(pose: .wave, size: 100, animation: .wiggle)

            Text("Waiting for your love...")
                .font(.romanticSub)
                .foregroundStyle(Color.inkSoft)

            GlassCard {
                VStack(spacing: Spacing.lg) {
                    Text("Your invite code")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkSoft)

                    Text(code)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .foregroundStyle(Color.rose)

                    ShareLink(item: "Join me on Sweetie! Use code: \(code)") {
                        Label("Share Code", systemImage: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.rose)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .sweetieGlass(cornerRadius: 14)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Animated waiting indicator
            HStack(spacing: Spacing.sm) {
                MascotView(pose: .wave, size: 32, animation: .wiggle)

                Text("Waiting for partner" + String(repeating: ".", count: dotCount))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.inkSoft)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roseDark)
            }
        }
        .task {
            // Animate the dots
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled else { break }
                dotCount = (dotCount % 3) + 1
            }
        }
        .task {
            // Poll every 5 seconds as a fallback in case realtime misses the partner join
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await supabase.refreshCouple()
                if supabase.authState == .paired { break }
            }
        }
    }

    // MARK: - Celebration

    private var celebrationContent: some View {
        Group {
            Spacer()
                .frame(height: Spacing.superHero)

            MascotView(pose: .excited, size: 100, animation: .bounce)

            Text("You're connected!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ink)
        }
    }

    // MARK: - Actions

    private func createCouple() async {
        isLoading = true
        errorMessage = nil
        logger.notice("createCouple tapped, userId: \(supabase.userId ?? "nil")")
        do {
            let code = try await supabase.createCouple()
            logger.notice("createCouple success, code: \(code)")
            withAnimation(.gentle) {
                pairingState = .waitingForPartner(code: code)
            }
            if let coupleId = supabase.couple?.id {
                supabase.subscribeToCouple(coupleId: coupleId)
            }
        } catch {
            logger.error("createCouple error: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func joinCouple() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.joinCouple(code: inviteCode)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
