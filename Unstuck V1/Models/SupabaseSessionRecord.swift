import Foundation
import Supabase

struct SupabaseSessionRecord: Codable {
    let id: UUID?
    let user_id: UUID
    let form_type: String
    let answers_json: [String: SupabaseAnswerRecord]
    let created_at: Date?
}

struct SupabaseAnswerRecord: Codable {
    let question_id: String
    let question_prompt: String
    let answer_value: String
}

struct SupabaseSessionInsert: Encodable {
    let user_id: UUID
    let form_type: String
    let answers_json: [String: SupabaseAnswerRecord]
}
