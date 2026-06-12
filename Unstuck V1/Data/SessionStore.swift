import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var errorMessage: String?

    private let userDefaults: UserDefaults
    private let sessionsKey = "unstuck.sessions"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadCachedSessions()
    }

    func saveSession(form: FormDefinition, answers: [String: String]) {
        let session = makeSession(form: form, answers: answers)
        saveLocalSession(session)
    }

    func saveSession(
        form: FormDefinition,
        answers: [String: String],
        userId: UUID?
    ) async {
        let session = makeSession(form: form, answers: answers)
        saveLocalSession(session)

        guard let userId else {
            return
        }

        do {
            try await SessionSyncService.saveSessionToSupabase(
                userId: userId,
                form: form,
                answers: answers
            )
            errorMessage = nil
        } catch {
            errorMessage = "Saved locally, but Supabase sync failed."
            print("Supabase session save failed: \(error)")
        }
    }

    func loadSessionsFromSupabase() async {
        do {
            let remoteSessions = try await SessionSyncService.loadSessionsFromSupabase()
            sessions = remoteSessions
            persistSessions()
            errorMessage = nil
        } catch {
            loadCachedSessions()
            errorMessage = "Unable to load Supabase sessions. Showing cached sessions."
            print("Supabase session load failed: \(error)")
        }
    }

    func clearInMemorySessions() {
        sessions = []
        errorMessage = nil
    }

    func deleteAllSessions() {
        sessions = []
        persistSessions()
    }

    private func makeSession(form: FormDefinition, answers: [String: String]) -> Session {
        let convertedAnswers = form.questions.compactMap { question -> Answer? in
            guard let value = answers[question.id] else {
                return nil
            }

            return Answer(
                questionId: question.id,
                questionText: question.prompt,
                value: value
            )
        }

        return Session(
            id: UUID(),
            formId: form.id,
            formTitle: form.title,
            completedAt: Date(),
            answers: convertedAnswers
        )
    }

    private func saveLocalSession(_ session: Session) {
        sessions.insert(session, at: 0)
        persistSessions()
    }

    private func loadCachedSessions() {
        guard let data = userDefaults.data(forKey: sessionsKey) else {
            sessions = []
            return
        }

        do {
            sessions = try JSONDecoder().decode([Session].self, from: data)
        } catch {
            sessions = []
            print("Failed to load saved sessions: \(error)")
        }
    }

    private func persistSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
}
