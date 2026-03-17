import Foundation

/// Lightweight HTTP client for widget extension → Supabase communication.
/// Reads credentials from App Group UserDefaults. Does NOT use the Supabase SDK.
///
/// Data flow:
///   SendTapIntent → WidgetAPIClient.sendTap()
///     → Read auth token + coupleId + userId from App Group
///     → POST /rest/v1/heart_taps { couple_id, sender_id, emoji }
///     → 201 Created (happy path)
///     → 401 (token expired) → return .tokenExpired
///     → URLError (offline) → return .networkError
enum WidgetAPIClient {
    enum SendResult: Sendable {
        case success
        case noCredentials
        case tokenExpired
        case networkError
        case serverError(Int)
    }

    static func sendTap(emoji: String = "💕") async -> SendResult {
        let manager = SharedDataManager.shared

        guard let token = manager.loadAuthToken(),
              let userId = manager.loadUserId(),
              let coupleId = manager.loadCoupleId(),
              let baseURL = manager.loadSupabaseURL() else {
            return .noCredentials
        }

        let anonKey = manager.loadAnonKey() ?? ""

        guard let url = URL(string: "\(baseURL)/rest/v1/heart_taps") else {
            return .noCredentials
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: String] = [
            "couple_id": coupleId,
            "sender_id": userId,
            "emoji": emoji,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .serverError(0)
            }

            switch httpResponse.statusCode {
            case 200...299:
                // Optimistic update: save the tap locally so the widget refreshes immediately
                manager.saveLastTap(emoji: emoji, senderName: "You")
                manager.appendActivity(SharedActivityItem(
                    kind: .tap, emoji: emoji, senderName: "You", caption: nil, timestamp: Date()
                ))
                manager.reloadWidgets()
                return .success
            case 401:
                return .tokenExpired
            default:
                return .serverError(httpResponse.statusCode)
            }
        } catch {
            return .networkError
        }
    }
}
