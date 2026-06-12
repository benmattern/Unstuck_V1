import Foundation

struct FormDefinition: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let questions: [FormQuestion]

    init(
        id: String,
        title: String,
        description: String? = nil,
        questions: [FormQuestion] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
    }
}
