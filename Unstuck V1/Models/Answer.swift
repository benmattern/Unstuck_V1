import Foundation

struct Answer: Identifiable, Codable {
    let id: UUID
    let questionId: String
    let questionText: String
    let value: String

    init(
        id: UUID = UUID(),
        questionId: String,
        questionText: String,
        value: String
    ) {
        self.id = id
        self.questionId = questionId
        self.questionText = questionText
        self.value = value
    }
}
