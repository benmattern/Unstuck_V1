import Foundation
import Supabase

enum SessionSyncService {
    static func saveSessionToSupabase(
        userId: UUID,
        form: FormDefinition,
        answers: [String: String]
    ) async throws {
        let record = SupabaseSessionInsert(
            user_id: userId,
            form_type: form.id,
            answers_json: answersJSON(for: form, answers: answers)
        )

        try await supabase
            .from("sessions")
            .insert(record)
            .execute()
    }

    static func loadSessionsFromSupabase() async throws -> [Session] {
        let response: PostgrestResponse<[SupabaseSessionRecord]> = try await supabase
            .from("sessions")
            .select()
            .order("created_at", ascending: false)
            .execute()

        return response.value.map { record in
            Session(
                id: record.id ?? UUID(),
                formId: record.form_type,
                formTitle: formTitle(for: record.form_type),
                completedAt: record.created_at ?? Date(),
                answers: answers(from: record)
            )
        }
    }

    private static func answersJSON(
        for form: FormDefinition,
        answers: [String: String]
    ) -> [String: SupabaseAnswerRecord] {
        form.questions.reduce(into: [String: SupabaseAnswerRecord]()) { result, question in
            guard let value = answers[question.id] else {
                return
            }

            result[question.id] = SupabaseAnswerRecord(
                question_id: question.id,
                question_prompt: question.prompt,
                answer_value: value
            )
        }
    }

    private static func answers(from record: SupabaseSessionRecord) -> [Answer] {
        record.answers_json
            .sorted { $0.key < $1.key }
            .map { _, answerRecord in
                Answer(
                    questionId: answerRecord.question_id,
                    questionText: answerRecord.question_prompt,
                    value: answerRecord.answer_value
                )
            }
    }

    private static func formTitle(for formType: String) -> String {
        switch formType {
        case SampleForms.shortCheckIn.id:
            SampleForms.shortCheckIn.title
        case SampleForms.mainForm.id:
            SampleForms.mainForm.title
        default:
            formType
        }
    }
}
