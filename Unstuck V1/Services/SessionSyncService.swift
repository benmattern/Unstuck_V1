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
        switch record.answers_json {
        case let .object(object):
            return answers(fromObject: object, formType: record.form_type)
        case let .array(array):
            return array.enumerated().compactMap { index, item in
                guard case let .object(object) = item else {
                    return nil
                }

                return answer(
                    from: object,
                    fallbackQuestionId: "answer_\(index + 1)",
                    formType: record.form_type
                )
            }
        default:
            return []
        }
    }

    private static func answers(
        fromObject object: [String: AnyJSON],
        formType: String
    ) -> [Answer] {
        object.keys.sorted().compactMap { questionId in
            guard let json = object[questionId] else {
                return nil
            }

            switch json {
            case let .object(answerObject):
                return answer(
                    from: answerObject,
                    fallbackQuestionId: questionId,
                    formType: formType
                )
            default:
                guard let value = scalarString(from: json) else {
                    return nil
                }

                return Answer(
                    questionId: questionId,
                    questionText: prompt(for: questionId, formType: formType),
                    value: value
                )
            }
        }
    }

    private static func answer(
        from object: [String: AnyJSON],
        fallbackQuestionId: String,
        formType: String
    ) -> Answer? {
        let questionId = firstScalarString(
            in: object,
            keys: ["question_id", "questionId", "id"]
        ) ?? fallbackQuestionId
        let questionText = firstScalarString(
            in: object,
            keys: ["question_prompt", "questionText", "prompt"]
        ) ?? prompt(for: questionId, formType: formType)

        guard let value = firstScalarString(
            in: object,
            keys: ["answer_value", "answer", "value"]
        ) else {
            return nil
        }

        return Answer(
            questionId: questionId,
            questionText: questionText,
            value: value
        )
    }

    private static func firstScalarString(
        in object: [String: AnyJSON],
        keys: [String]
    ) -> String? {
        keys.compactMap { scalarString(from: object[$0]) }.first
    }

    private static func scalarString(from json: AnyJSON?) -> String? {
        switch json {
        case let .string(value):
            return value
        case let .integer(value):
            return String(value)
        case let .double(value):
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        default:
            return nil
        }
    }

    private static func prompt(for questionId: String, formType: String) -> String {
        switch formType {
        case SampleForms.shortCheckIn.id:
            return SampleForms.shortCheckIn.questions.first { $0.id == questionId }?.prompt ?? questionId
        case SampleForms.mainForm.id:
            return SampleForms.mainForm.questions.first { $0.id == questionId }?.prompt ?? questionId
        default:
            return questionId
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
