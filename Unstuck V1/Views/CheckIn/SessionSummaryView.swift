import Supabase
import SwiftUI

struct SessionSummaryView: View {
    let form: FormDefinition
    let answers: [String: String]
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var userStatsStore: UserStatsStore
    @State private var isSaving = false

    private var answeredQuestions: [(question: FormQuestion, answer: String)] {
        form.questions.compactMap { question in
            guard let answer = answers[question.id],
                  !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return (question, answer)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                header
                summarySection
                actions
            }
            .padding(AppTheme.Spacing.large)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(form.title)
                    .font(.title2.weight(.semibold))

                if let description = form.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader("Summary", subtitle: "Review your answers before saving.")

            if answeredQuestions.isEmpty {
                AppCard {
                    Text("No answers entered.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(answeredQuestions, id: \.question.id) { item in
                        answerCard(question: item.question, answer: item.answer)
                    }
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Button {
                saveSession()
            } label: {
                PrimaryButton(isSaving ? "Saving..." : "Save Session", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .opacity(isSaving ? 0.6 : 1.0)

            Button {
                dismiss()
            } label: {
                SecondaryButton("Back to Form", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
    }

    private func answerCard(question: FormQuestion, answer: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(question.prompt)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(answer)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func saveSession() {
        guard !isSaving else {
            return
        }

        isSaving = true

        Task {
            let userId = authService.currentUser?.id
            await sessionStore.saveSession(
                form: form,
                answers: answers,
                userId: userId
            )

            if let userId {
                await userStatsStore.recordCompletion(userId: userId)
            }
            onSaved()
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        SessionSummaryView(
            form: SampleForms.shortCheckIn,
            answers: [
                "current_focus": "Finish the first native app pass.",
                "stuck_level": "2",
                "next_action": "Review the summary screen."
            ],
            onSaved: {}
        )
        .environmentObject(AuthService(restoreSessionOnInit: false))
        .environmentObject(SessionStore())
        .environmentObject(StreakStore())
        .environmentObject(UserStatsStore())
        .environmentObject(AppearanceStore())
    }
}
