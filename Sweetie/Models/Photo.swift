import Foundation

struct Photo: Codable, Identifiable, Hashable {
    let id: String
    let coupleId: String
    let senderId: String
    let storagePath: String
    var caption: String?
    var reaction: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case senderId = "sender_id"
        case storagePath = "storage_path"
        case caption
        case reaction
        case createdAt = "created_at"
    }
}
