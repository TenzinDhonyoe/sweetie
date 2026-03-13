import Foundation

struct Couple: Codable, Identifiable, Hashable {
    let id: String
    let partner1: String
    var partner2: String?
    let inviteCode: String
    var reunionDate: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case partner1 = "partner_1"
        case partner2 = "partner_2"
        case inviteCode = "invite_code"
        case reunionDate = "reunion_date"
        case createdAt = "created_at"
    }
}
