import Foundation

struct Session: Identifiable, Codable {
    let id: UUID
    let formId: String
    let formTitle: String
    let completedAt: Date
    let answers: [Answer]

    init(
        id: UUID = UUID(),
        formId: String,
        formTitle: String,
        completedAt: Date = Date(),
        answers: [Answer] = []
    ) {
        self.id = id
        self.formId = formId
        self.formTitle = formTitle
        self.completedAt = completedAt
        self.answers = answers
    }
}
