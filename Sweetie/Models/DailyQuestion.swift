import Foundation

struct DailyQuestion: Codable, Identifiable, Hashable {
    let id: String
    let coupleId: String
    var questionText: String
    var dayNumber: Int
    var partner1Answer: String?
    var partner2Answer: String?
    var unlockedAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case questionText = "question_text"
        case dayNumber = "day_number"
        case partner1Answer = "partner_1_answer"
        case partner2Answer = "partner_2_answer"
        case unlockedAt = "unlocked_at"
        case createdAt = "created_at"
    }
}
