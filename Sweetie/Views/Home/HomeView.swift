import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(SupabaseService.self) private var supabase

    @State private var partnerProfile: Profile?
    @State private var recentActivity: [ActivityItem] = []
    @State private var questions: [DailyQuestion] = []
    @State private var isLoading = true

    // Photo flow
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showCaptionSheet = false
    @State private var pendingCaption: String?
    @State private var shouldUploadPhoto = false

    // Note flow
    @State private var showNoteSheet = false

    private var userId: String? {
        supabase.userId
    }

    // FAB
    @State private var showFABMenu = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // 1. Partner Status Pill
                        partnerStatusSection

                        // 2. Countdown Card
                        countdownSection

                        // 3. Today's Question
                        todayQuestionSection

                        // 4. Recent Activity
                        recentActivitySection
                    }
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 100)
                }

                // Dim overlay
                if showFABMenu {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                showFABMenu = false
                            }
                        }
                        .transition(.opacity)
                }

                // FAB Menu
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        fabMenu
                    }
                }
            }
            .background(BackgroundGradient())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .task {
            await loadData()
            subscribeToRealtime()
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if capturedImage != nil {
                // Delay to let fullScreenCover dismiss animation finish
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showCaptionSheet = true
                }
            }
        }) {
            ImagePicker { image in
                capturedImage = image
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showCaptionSheet, onDismiss: {
            if shouldUploadPhoto, let image = capturedImage {
                let caption = pendingCaption
                shouldUploadPhoto = false
                pendingCaption = nil
                Task {
                    await uploadPhoto(image: image, caption: caption)
                    capturedImage = nil
                }
            } else {
                capturedImage = nil
            }
        }) {
            if let image = capturedImage {
                PhotoCaptionSheet(image: image) { caption in
                    pendingCaption = caption
                    shouldUploadPhoto = true
                }
            }
        }
        .alert("Upload Error", isPresented: Binding(
            get: { photoUploadError != nil },
            set: { if !$0 { photoUploadError = nil } }
        )) {
            Button("OK") { photoUploadError = nil }
        } message: {
            Text(photoUploadError ?? "")
        }
        .sheet(isPresented: $showNoteSheet) {
            ComposeNoteSheet(category: .instant) { content, _, _ in
                Task {
                    try? await supabase.sendNote(content: content, category: .instant)
                    await refreshActivity()
                }
            }
        }
    }

    // MARK: - Partner Status

    private var partnerStatusSection: some View {
        Group {
            if let partner = partnerProfile {
                let tzOverride = UserDefaults.standard.string(forKey: "partnerTimezoneOverride")
                let tz = tzOverride ?? partner.timezone ?? TimeZone.current.identifier
                PartnerStatusPill(
                    partnerName: partner.displayName ?? "Partner",
                    timezone: tz,
                    isOnline: supabase.isPartnerOnline
                )
            }
        }
    }

    // MARK: - Countdown

    private var countdownSection: some View {
        Group {
            if let reunionDateString = supabase.couple?.reunionDate,
               let reunionDate = DateFormatting.parse(reunionDateString) {
                CountdownCard(reunionDate: reunionDate)
            } else {
                CountdownCard(reunionDate: nil)
            }
        }
    }

    // MARK: - FAB Menu

    private var fabMenu: some View {
        VStack(alignment: .trailing, spacing: Spacing.sm) {
            if showFABMenu {
                fabPill(emoji: "💌", label: "Note", delay: 0.05) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        showFABMenu = false
                    }
                    showNoteSheet = true
                }

                fabPill(emoji: "📸", label: "Photo", delay: 0) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                        showFABMenu = false
                    }
                    showCamera = true
                }
            }

            // Main + button
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                    showFABMenu.toggle()
                }
                HapticService.tap()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.rose)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.rose.opacity(0.3), radius: 12, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(showFABMenu ? 45 : 0))
                        .animation(.spring(duration: 0.35, bounce: 0.25), value: showFABMenu)
                }
            }
            .buttonStyle(QuickActionButtonStyle())
        }
        .padding(.trailing, Spacing.xl)
        .padding(.bottom, Spacing.xl)
    }

    private func fabPill(emoji: String, label: String, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(emoji)
                    .font(.system(size: 20))

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .buttonStyle(QuickActionButtonStyle())
        .transition(
            .scale(scale: 0.4, anchor: .bottomTrailing)
            .combined(with: .opacity)
            .combined(with: .offset(y: 10))
        )
    }

    // MARK: - Today's Question

    private var todaysQuestion: DailyQuestion? {
        guard let couple = supabase.couple,
              let createdDate = DateFormatting.parse(couple.createdAt) else { return nil }
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
        let todayDay = min(daysSinceCreation + 1, 10)
        return questions.first { $0.dayNumber == todayDay }
    }

    private var todayQuestionSection: some View {
        Group {
            if let todayQ = todaysQuestion {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Today's Question")
                        .sectionHeader()

                    TodayQuestionView(
                        question: todayQ,
                        userId: userId,
                        isPartner1: supabase.couple?.partner1 == userId,
                        partnerName: partnerProfile?.displayName ?? "Partner",
                        onSubmit: { answer in
                            Task {
                                try? await supabase.answerQuestion(questionId: todayQ.id, answer: answer)

                                let refreshed = await supabase.fetchQuestions()
                                if let updated = refreshed.first(where: { $0.id == todayQ.id }),
                                   updated.partner1Answer != nil && updated.partner2Answer != nil && updated.unlockedAt == nil {
                                    try? await supabase.unlockQuestion(questionId: todayQ.id)
                                }

                                questions = await supabase.fetchQuestions()
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            } else if recentActivity.isEmpty {
                emptyState
            } else {
                Text("Recent")
                    .sectionHeader()

                LazyVStack(spacing: Spacing.md) {
                    ForEach(recentActivity, id: \.id) { item in
                        activityCard(item)
                    }
                }
            }
        }
    }

    private func activityCard(_ item: ActivityItem) -> some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                switch item.type {
                case .photo:
                    // Photo thumbnail
                    if let photoPath = item.photoPath,
                       let url = supabase.photoURL(for: photoPath) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            default:
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.inkFaint.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("📸")
                                            .font(.system(size: 16))
                                    )
                            }
                        }
                    } else {
                        Text("📸")
                            .font(.system(size: 20))
                    }

                case .note:
                    Text("💌")
                        .font(.system(size: 20))

                case .tap:
                    Text(item.icon)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.description)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)

                    if let date = DateFormatting.parse(item.createdAt) {
                        if item.type == .tap {
                            Text(formatTapTime(date: date, isPartnerTap: item.isPartnerTap))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.inkFaint)
                        } else {
                            Text(DateFormatting.relativeString(from: date))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.inkFaint)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    private func formatTapTime(date: Date, isPartnerTap: Bool) -> String {
        let localTime = DateFormatting.shortTime(date)

        if isPartnerTap, let partnerTZ = partnerProfile?.timezone,
           let tz = TimeZone(identifier: partnerTZ), tz != .current {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            formatter.timeZone = tz
            let partnerTime = formatter.string(from: date)
            return "\(localTime) (their \(partnerTime))"
        }

        return localTime
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: Spacing.lg) {
                MascotView(pose: .hug, size: 80, animation: .breathe)

                Text("Send the first tap!")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.inkSoft)

                Text("Tap the heart tab to send 💕")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        // Load partner first so activity feed has the name
        partnerProfile = await supabase.fetchPartnerProfile()
        recentActivity = await buildActivityFeed()

        // Load questions
        await supabase.seedQuestionsIfNeeded()
        questions = await supabase.fetchQuestions()

        isLoading = false
    }

    private func refreshActivity() async {
        recentActivity = await buildActivityFeed()
    }

    private func buildActivityFeed() async -> [ActivityItem] {
        let userId = await supabase.resolveUserId()
        let partnerName = partnerProfile?.displayName ?? "Partner"

        async let taps = supabase.fetchRecentTaps(limit: 10)
        async let photos = supabase.fetchRecentPhotos(limit: 10)
        async let notes = supabase.fetchRecentNotes(limit: 10)

        var items: [ActivityItem] = []

        for tap in await taps {
            let isMe = tap.senderId == userId
            items.append(ActivityItem(
                id: tap.id,
                icon: tap.emoji ?? "💕",
                description: isMe ? "You sent \(tap.emoji ?? "💕")" : "\(partnerName) sent \(tap.emoji ?? "💕")",
                createdAt: tap.createdAt,
                type: .tap,
                isPartnerTap: !isMe
            ))
        }

        for photo in await photos {
            let isMe = photo.senderId == userId
            let desc = photo.caption ?? (isMe ? "You sent a photo" : "\(partnerName) sent a photo")
            items.append(ActivityItem(
                id: photo.id,
                icon: "📸",
                description: desc,
                createdAt: photo.createdAt,
                type: .photo,
                photoPath: photo.storagePath
            ))
        }

        for note in await notes {
            let isMe = note.senderId == userId
            let desc: String
            if !isMe && !note.read {
                desc = "You have an unread love note"
            } else if isMe {
                let preview = String(note.content.prefix(60))
                desc = preview + (note.content.count > 60 ? "…" : "")
            } else {
                let preview = String(note.content.prefix(60))
                desc = preview + (note.content.count > 60 ? "…" : "")
            }
            items.append(ActivityItem(
                id: note.id,
                icon: "💌",
                description: desc,
                createdAt: note.createdAt,
                type: .note
            ))
        }

        return items.sorted { $0.createdAt > $1.createdAt }
    }

    private func subscribeToRealtime() {
        guard let coupleId = supabase.couple?.id else { return }
        supabase.subscribeToHomeFeed(coupleId: coupleId) {
            Task { await refreshActivity() }
        }
    }

    // MARK: - Photo Upload

    @State private var photoUploadError: String?

    private func uploadPhoto(image: UIImage, caption: String?) async {
        guard let compressed = compressImage(image) else { return }
        do {
            try await supabase.uploadPhoto(imageData: compressed, caption: caption)
            await refreshActivity()
        } catch {
            photoUploadError = "Photo upload failed. Please try again."
        }
    }

    private func compressImage(_ image: UIImage) -> Data? {
        let maxWidth: CGFloat = 1200
        let scale = image.size.width > maxWidth ? maxWidth / image.size.width : 1.0
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Quick Action Button Style

private struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Activity Item

struct ActivityItem: Identifiable {
    let id: String
    let icon: String
    let description: String
    let createdAt: String
    let type: ActivityType
    var isPartnerTap: Bool = false
    var photoPath: String? = nil

    enum ActivityType {
        case tap, photo, note
    }
}
