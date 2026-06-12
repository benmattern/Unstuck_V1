import Foundation

struct FormQuestion: Identifiable, Codable {
    let id: String
    let prompt: String
    let type: QuestionType
    let options: [String]?

    init(
        id: String,
        prompt: String,
        type: QuestionType,
        options: [String]? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.type = type
        self.options = options
    }
}

enum QuestionType: String, Codable {
    case rating
    case singleChoice
    case text
}
