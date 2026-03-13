import Foundation

struct Tap: Codable, Identifiable, Hashable {
    let id: String
    let coupleId: String
    let senderId: String
    var pattern: String?
    var emoji: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case senderId = "sender_id"
        case pattern
        case emoji
        case createdAt = "created_at"
    }
}
