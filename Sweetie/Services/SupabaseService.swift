import Foundation
import Supabase
import Realtime
import WidgetKit

enum AuthState {
    case loading
    case unauthenticated
    case unpaired
    case paired
}

@Observable
@MainActor
final class SupabaseService {
    private(set) var authState: AuthState = .loading
    private(set) var profile: Profile?
    private(set) var couple: Couple?

    private var coupleChannel: RealtimeChannelV2?

    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var isWaitingForPartner: Bool = UserDefaults.standard.bool(forKey: "isWaitingForPartner") {
        didSet { UserDefaults.standard.set(isWaitingForPartner, forKey: "isWaitingForPartner") }
    }

    let client: SupabaseClient

    /// Synchronous user ID (lowercased to match Supabase). Nil if no active session.
    var userId: String? {
        try? client.auth.currentSession?.user.id.uuidString.lowercased()
    }

    /// Async user ID (lowercased). Fetches session if needed.
    func resolveUserId() async -> String? {
        (try? await client.auth.session.user.id.uuidString)?.lowercased()
    }

    init() {
        guard let url = URL(string: Self.supabaseURL) else {
            preconditionFailure("Invalid Supabase URL: \(Self.supabaseURL)")
        }
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: Self.supabaseAnonKey)

        Task {
            await listenForAuthChanges()
        }
    }

    private static var supabaseURL: String {
        "https://sitvwvojfhntakububpv.supabase.co"
    }

    private static var supabaseAnonKey: String {
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNpdHZ3dm9qZmhudGFrdWJ1YnB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxNzkxMDQsImV4cCI6MjA4ODc1NTEwNH0.3Lr0OceWhVQ37eRIcguTQKQbGegoI8HvVqPoIZP9Q1M"
    }

    // MARK: - Auth

    private func listenForAuthChanges() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .initialSession:
                if session != nil {
                    await refreshProfile()
                } else {
                    authState = .unauthenticated
                }
            case .signedIn:
                await refreshProfile()
            case .signedOut:
                profile = nil
                couple = nil
                unsubscribeFromCouple()
                authState = .unauthenticated
            default:
                break
            }
        }
    }

    func signInAnonymously() async {
        do {
            try await client.auth.signInAnonymously()
        } catch {
            #if DEBUG
            print("[Sweetie] Anonymous sign-in failed: \(error)")
            #endif
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Profile

    func refreshProfile() async {
        guard let userId = await resolveUserId() else {
            authState = .unauthenticated
            return
        }

        do {
            let fetchedProfile: Profile = try await client.from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            self.profile = fetchedProfile
            await refreshCouple()
        } catch {
            authState = .unpaired
        }
    }

    func updateProfile(displayName: String, timezone: String) async throws {
        guard let userId = await resolveUserId() else { return }

        try await client.from("profiles")
            .update([
                "display_name": displayName,
                "timezone": timezone
            ])
            .eq("id", value: userId)
            .execute()

        await refreshProfile()
    }

    func updateDisplayName(_ displayName: String) async throws {
        guard let userId = await resolveUserId() else { return }

        try await client.from("profiles")
            .update(["display_name": displayName])
            .eq("id", value: userId)
            .execute()

        await refreshProfile()
    }

    func updateAvatar(imageData: Data) async throws {
        guard let userId = await resolveUserId() else { return }

        let path = "\(userId).jpg"

        try await client.storage
            .from("avatars")
            .upload(path, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))

        guard let publicURL = try? client.storage
            .from("avatars")
            .getPublicURL(path: path) else { return }

        try await client.from("profiles")
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: userId)
            .execute()

        await refreshProfile()
    }

    func updateSleepSchedule(sleepStart: String, sleepEnd: String) async throws {
        guard let userId = await resolveUserId() else { return }

        try await client.from("profiles")
            .update([
                "sleep_start": sleepStart,
                "sleep_end": sleepEnd
            ])
            .eq("id", value: userId)
            .execute()

        await refreshProfile()
    }

    func updatePushToken(_ token: String) async throws {
        guard let userId = await resolveUserId() else { return }

        try await client.from("profiles")
            .update(["push_token": token])
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Couple

    func refreshCouple() async {
        guard let userId = await resolveUserId() else { return }

        do {
            let fetchedCouple: Couple = try await client.from("couples")
                .select()
                .or("partner_1.eq.\(userId),partner_2.eq.\(userId)")
                .single()
                .execute()
                .value

            self.couple = fetchedCouple

            // Sync reunion date to widgets
            if let dateString = fetchedCouple.reunionDate {
                SharedDataManager.shared.saveReunionDate(DateFormatting.parse(dateString))
            }

            if fetchedCouple.partner2 != nil {
                authState = .paired
                isWaitingForPartner = false
            } else {
                authState = .unpaired
                if isWaitingForPartner {
                    subscribeToCouple(coupleId: fetchedCouple.id)
                }
            }
        } catch {
            authState = .unpaired
        }
    }

    func createCouple() async throws -> String {
        guard let userId = await resolveUserId() else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let result: Couple = try await client.from("couples")
            .insert(["partner_1": userId])
            .select()
            .single()
            .execute()
            .value

        self.couple = result
        authState = .unpaired
        return result.inviteCode
    }

    func joinCouple(code: String) async throws {
        do {
            try await client.rpc("join_couple", params: ["code": code]).execute()
        } catch {
            let message = error.localizedDescription
            if message.contains("Invalid invite code") {
                throw NSError(domain: "SupabaseService", code: 10, userInfo: [NSLocalizedDescriptionKey: "That code doesn't match any couple. Check the code and try again."])
            } else if message.contains("already has two partners") {
                throw NSError(domain: "SupabaseService", code: 11, userInfo: [NSLocalizedDescriptionKey: "This couple is already paired with someone else."])
            } else if message.contains("cannot join your own") {
                throw NSError(domain: "SupabaseService", code: 12, userInfo: [NSLocalizedDescriptionKey: "You can't join your own couple! Share the code with your partner."])
            } else {
                throw NSError(domain: "SupabaseService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Couldn't join couple. Please try again."])
            }
        }
        await refreshCouple()
    }

    func updateReunionDate(_ date: Date) async throws {
        guard let coupleId = couple?.id else {
            throw NSError(domain: "SupabaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No couple found — please pair first"])
        }

        let dateString = DateFormatting.iso8601String(from: date)
        #if DEBUG
        print("[Sweetie] Saving reunion date: \(dateString) for couple: \(coupleId)")
        #endif

        try await client.from("couples")
            .update(["reunion_date": dateString])
            .eq("id", value: coupleId)
            .execute()

        #if DEBUG
        print("[Sweetie] Reunion date saved to Supabase successfully")
        #endif

        // Save locally for widgets
        SharedDataManager.shared.saveReunionDate(date)
        SharedDataManager.shared.reloadWidgets()

        // Update local couple model directly so UI reflects immediately
        self.couple = Couple(
            id: coupleId,
            partner1: couple?.partner1 ?? "",
            partner2: couple?.partner2,
            inviteCode: couple?.inviteCode ?? "",
            reunionDate: dateString,
            createdAt: couple?.createdAt ?? ""
        )
    }

    // MARK: - Partner

    func fetchPartnerProfile() async -> Profile? {
        guard let couple, let userId = await resolveUserId() else { return nil }
        let partnerId = couple.partner1 == userId ? couple.partner2 : couple.partner1
        guard let partnerId else { return nil }

        let partner: Profile? = try? await client.from("profiles")
            .select()
            .eq("id", value: partnerId)
            .single()
            .execute()
            .value

        if let name = partner?.displayName {
            SharedDataManager.shared.savePartnerName(name)
        }

        return partner
    }

    // MARK: - Taps

    func sendTap(pattern: String = "default", emoji: String = "💕") async throws {
        guard let coupleId = couple?.id,
              let userId = await resolveUserId() else { return }

        try await client.from("taps")
            .insert([
                "couple_id": coupleId,
                "sender_id": userId,
                "emoji": emoji,
                "pattern": pattern
            ])
            .execute()

        await broadcastTap(emoji: emoji, pattern: pattern)
    }

    func broadcastTap(emoji: String, pattern: String) async {
        guard let coupleId = couple?.id,
              let userId = await resolveUserId() else { return }

        let channel = client.realtimeV2.channel("couple:\(coupleId):taps")
        await channel.subscribe()
        try? await channel.broadcast(
            event: "tap",
            message: [
                "sender_id": .string(userId),
                "emoji": .string(emoji),
                "pattern": .string(pattern)
            ]
        )
        await channel.unsubscribe()
    }

    // MARK: - Tap Broadcast Subscription

    private var tapBroadcastChannel: RealtimeChannelV2?

    func subscribeToBroadcastTaps(coupleId: String, onTapReceived: @escaping @MainActor (_ emoji: String, _ pattern: String) -> Void) {
        unsubscribeFromBroadcastTaps()

        let channel = client.realtimeV2.channel("couple:\(coupleId):taps")

        let broadcasts = channel.broadcastStream(event: "tap")

        Task {
            await channel.subscribe()

            let userId = await resolveUserId()

            for await payload in broadcasts {
                guard let senderValue = payload["sender_id"],
                      case .string(let senderId) = senderValue,
                      senderId != userId else { continue }

                let emoji: String
                if let emojiValue = payload["emoji"], case .string(let e) = emojiValue {
                    emoji = e
                } else {
                    emoji = "💕"
                }

                let pattern: String
                if let patternValue = payload["pattern"], case .string(let p) = patternValue {
                    pattern = p
                } else {
                    pattern = "default"
                }

                // Sync to widget
                let partnerName = SharedDataManager.shared.loadPartnerName()
                SharedDataManager.shared.saveLastTap(emoji: emoji, senderName: partnerName)
                SharedDataManager.shared.appendActivity(SharedActivityItem(
                    kind: .tap, emoji: emoji, senderName: partnerName, caption: nil, timestamp: Date()
                ))
                SharedDataManager.shared.reloadWidgets()

                onTapReceived(emoji, pattern)
            }
        }

        self.tapBroadcastChannel = channel
    }

    func unsubscribeFromBroadcastTaps() {
        if let channel = tapBroadcastChannel {
            Task {
                await channel.unsubscribe()
            }
            tapBroadcastChannel = nil
        }
    }

    // MARK: - Recent Activity

    func fetchRecentTaps(limit: Int = 5) async -> [Tap] {
        guard let coupleId = couple?.id else { return [] }
        return (try? await client.from("taps")
            .select()
            .eq("couple_id", value: coupleId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value) ?? []
    }

    func fetchRecentPhotos(limit: Int = 5) async -> [Photo] {
        guard let coupleId = couple?.id else { return [] }
        return (try? await client.from("photos")
            .select()
            .eq("couple_id", value: coupleId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value) ?? []
    }

    func fetchRecentNotes(limit: Int = 5) async -> [LoveNote] {
        guard let coupleId = couple?.id else { return [] }
        return (try? await client.from("love_notes")
            .select()
            .eq("couple_id", value: coupleId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value) ?? []
    }

    // MARK: - Love Notes

    func fetchNotes(category: NoteCategory? = nil, limit: Int = 30) async -> [LoveNote] {
        guard let coupleId = couple?.id else { return [] }
        var query = client.from("love_notes")
            .select()
            .eq("couple_id", value: coupleId)

        if let category {
            query = query.eq("category", value: category.rawValue)
        }

        return (try? await query
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value) ?? []
    }

    func sendNote(content: String, category: NoteCategory, openWhenLabel: String? = nil, deliverAt: Date? = nil) async throws {
        guard let coupleId = couple?.id,
              let userId = await resolveUserId() else { return }

        var row: [String: String] = [
            "couple_id": coupleId,
            "sender_id": userId,
            "content": content,
            "category": category.rawValue,
            "delivered": category == .instant ? "true" : "false",
            "read": "false"
        ]

        if let openWhenLabel {
            row["open_when_label"] = openWhenLabel
        }

        if let deliverAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            row["deliver_at"] = formatter.string(from: deliverAt)
        }

        try await client.from("love_notes")
            .insert(row)
            .execute()
    }

    func markNoteRead(noteId: String) async throws {
        try await client.from("love_notes")
            .update(["read": "true"])
            .eq("id", value: noteId)
            .execute()
    }

    // MARK: - Daily Questions

    func fetchQuestions() async -> [DailyQuestion] {
        guard let coupleId = couple?.id else { return [] }
        return (try? await client.from("daily_questions")
            .select()
            .eq("couple_id", value: coupleId)
            .order("day_number", ascending: true)
            .execute()
            .value) ?? []
    }

    func answerQuestion(questionId: String, answer: String) async throws {
        guard let couple, let userId = await resolveUserId() else { return }

        let isPartner1 = couple.partner1 == userId
        let column = isPartner1 ? "partner_1_answer" : "partner_2_answer"

        try await client.from("daily_questions")
            .update([column: answer])
            .eq("id", value: questionId)
            .execute()
    }

    func unlockQuestion(questionId: String) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = formatter.string(from: Date())

        try await client.from("daily_questions")
            .update(["unlocked_at": now])
            .eq("id", value: questionId)
            .execute()
    }

    func seedQuestionsIfNeeded() async {
        guard let coupleId = couple?.id else { return }

        let existing = await fetchQuestions()
        if !existing.isEmpty { return }

        let questions = [
            "What's something small I do that makes you feel loved?",
            "What's your favorite memory of us so far?",
            "What song reminds you of us?",
            "What do you miss most about me right now?",
            "What's one dream you want us to do together?",
            "When did you first know you loved me?",
            "What's something you've never told me?",
            "What's the hardest part about the distance?",
            "Where do you see us in five years?",
            "What would you do if I were next to you right now?"
        ]

        for (index, q) in questions.enumerated() {
            try? await client.from("daily_questions")
                .insert([
                    "couple_id": coupleId,
                    "question_text": q,
                    "day_number": "\(index + 1)"
                ])
                .execute()
        }
    }

    // MARK: - Photo Upload & Storage

    func uploadPhoto(imageData: Data, caption: String?) async throws {
        guard let coupleId = couple?.id,
              let userId = await resolveUserId() else { return }

        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "\(coupleId)/\(timestamp).jpg"

        try await client.storage
            .from("couple-photos")
            .upload(path, data: imageData, options: .init(contentType: "image/jpeg"))

        var row: [String: String] = [
            "couple_id": coupleId,
            "sender_id": userId,
            "storage_path": path
        ]
        if let caption, !caption.isEmpty {
            row["caption"] = caption
        }

        try await client.from("photos")
            .insert(row)
            .execute()

    }

    func photoURL(for storagePath: String) -> URL? {
        try? client.storage
            .from("couple-photos")
            .getPublicURL(path: storagePath)
    }

    func reactToPhoto(photoId: String, reaction: String) async throws {
        try await client.from("photos")
            .update(["reaction": reaction])
            .eq("id", value: photoId)
            .execute()
    }

    func fetchPhotos(limit: Int = 20) async -> [Photo] {
        guard let coupleId = couple?.id else { return [] }
        return (try? await client.from("photos")
            .select()
            .eq("couple_id", value: coupleId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value) ?? []
    }

    // MARK: - Realtime

    func subscribeToCouple(coupleId: String) {
        unsubscribeFromCouple()

        let channel = client.realtimeV2.channel("couple-\(coupleId)")

        let changes = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "couples",
            filter: "id=eq.\(coupleId)"
        )

        Task {
            await channel.subscribe()

            for await update in changes {
                if let partner2 = update.record["partner_2"],
                   case .string = partner2 {
                    await refreshCouple()
                }
            }
        }

        self.coupleChannel = channel
    }

    func unsubscribeFromCouple() {
        if let channel = coupleChannel {
            Task {
                await channel.unsubscribe()
            }
            coupleChannel = nil
        }
    }

    // MARK: - Home Feed Realtime

    private var homeChannel: RealtimeChannelV2?
    private(set) var isPartnerOnline = false

    func subscribeToHomeFeed(coupleId: String, onNewActivity: @escaping @MainActor () -> Void) {
        unsubscribeFromHomeFeed()

        let channel = client.realtimeV2.channel("home-\(coupleId)")

        let tapChanges = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "taps",
            filter: "couple_id=eq.\(coupleId)"
        )

        let photoChanges = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "photos",
            filter: "couple_id=eq.\(coupleId)"
        )

        let noteChanges = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "love_notes",
            filter: "couple_id=eq.\(coupleId)"
        )

        let presenceChanges = channel.presenceChange()

        Task {
            await channel.subscribe()
            let userId = await resolveUserId()
            let partnerName = SharedDataManager.shared.loadPartnerName()

            // Track our own presence
            try? await channel.track(state: ["user_id": .string(profile?.id ?? "")])

            // Listen for inserts in parallel tasks
            Task {
                for await action in tapChanges {
                    if let senderValue = action.record["sender_id"],
                       case .string(let senderId) = senderValue,
                       senderId != userId {
                        let emoji: String
                        if let emojiValue = action.record["emoji"],
                           case .string(let e) = emojiValue {
                            emoji = e
                        } else {
                            emoji = "💕"
                        }
                        
                        SharedDataManager.shared.saveLastTap(emoji: emoji, senderName: partnerName)
                        SharedDataManager.shared.appendActivity(SharedActivityItem(
                            kind: .tap, emoji: emoji, senderName: partnerName, caption: nil, timestamp: Date()
                        ))
                        SharedDataManager.shared.reloadWidgets()
                    }
                    onNewActivity()
                }
            }
            Task {
                for await action in photoChanges {
                    if let senderValue = action.record["sender_id"],
                       case .string(let senderId) = senderValue,
                       senderId != userId {
                        let caption: String?
                        if let captionValue = action.record["caption"],
                           case .string(let c) = captionValue {
                            caption = c
                        } else {
                            caption = nil
                        }

                        // Download photo for widget
                        if let pathValue = action.record["storage_path"],
                           case .string(let storagePath) = pathValue,
                           let url = self.photoURL(for: storagePath),
                           let (data, _) = try? await URLSession.shared.data(from: url) {
                            SharedDataManager.shared.saveLatestPhoto(
                                imageData: data, senderName: partnerName, caption: caption
                            )
                        }

                        SharedDataManager.shared.appendActivity(SharedActivityItem(
                            kind: .photo, emoji: nil, senderName: partnerName, caption: caption, timestamp: Date()
                        ))
                        SharedDataManager.shared.reloadWidgets()
                    }
                    onNewActivity()
                }
            }
            Task {
                for await action in noteChanges {
                    if let senderValue = action.record["sender_id"],
                       case .string(let senderId) = senderValue,
                       senderId != userId {
                        SharedDataManager.shared.appendActivity(SharedActivityItem(
                            kind: .tap, emoji: "💌", senderName: partnerName, caption: nil, timestamp: Date()
                        ))
                        SharedDataManager.shared.reloadWidgets()
                    }
                    onNewActivity()
                }
            }
            Task {
                for await action in presenceChanges {
                    let joins = (try? action.decodeJoins(as: [[String: String]].self)) ?? []
                    let leaves = (try? action.decodeLeaves(as: [[String: String]].self)) ?? []
                    // Simple heuristic: if someone joins, partner may be online
                    // If someone leaves, they may be offline
                    if !joins.isEmpty {
                        self.isPartnerOnline = true
                    } else if !leaves.isEmpty {
                        self.isPartnerOnline = false
                    }
                }
            }
        }

        self.homeChannel = channel
    }

    func unsubscribeFromHomeFeed() {
        if let channel = homeChannel {
            Task {
                await channel.unsubscribe()
            }
            homeChannel = nil
        }
        isPartnerOnline = false
    }

    // MARK: - Widget Data Sync

    func syncWidgetData() {
        if let dateString = couple?.reunionDate {
            SharedDataManager.shared.saveReunionDate(DateFormatting.parse(dateString))
        }
        SharedDataManager.shared.reloadWidgets()
    }
}
