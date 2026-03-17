import Foundation

struct LoveNote: Codable, Identifiable, Hashable {
    let id: String
    let coupleId: String
    let senderId: String
    var content: String
    var delivered: Bool
    var read: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case senderId = "sender_id"
        case content
        case delivered
        case read
        case createdAt = "created_at"
    }
}
