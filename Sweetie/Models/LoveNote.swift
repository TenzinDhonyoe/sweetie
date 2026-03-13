import Foundation

enum NoteCategory: String, Codable, Hashable {
    case instant
    case openWhen = "open_when"
    case morning
    case night
}

struct LoveNote: Codable, Identifiable, Hashable {
    let id: String
    let coupleId: String
    let senderId: String
    var content: String
    var category: NoteCategory
    var openWhenLabel: String?
    var deliverAt: String?
    var delivered: Bool
    var read: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case senderId = "sender_id"
        case content
        case category
        case openWhenLabel = "open_when_label"
        case deliverAt = "deliver_at"
        case delivered
        case read
        case createdAt = "created_at"
    }
}
