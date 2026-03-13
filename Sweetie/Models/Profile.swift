import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: String
    var displayName: String?
    var avatarUrl: String?
    var timezone: String?
    var sleepStart: String
    var sleepEnd: String
    var pushToken: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case timezone
        case sleepStart = "sleep_start"
        case sleepEnd = "sleep_end"
        case pushToken = "push_token"
        case createdAt = "created_at"
    }
}
