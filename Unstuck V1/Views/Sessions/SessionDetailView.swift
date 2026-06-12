import SwiftUI

struct SessionDetailView: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                header

                VStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(session.answers) { answer in
                        answerCard(answer)
                    }
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(session.formTitle)
                    .font(.title2.weight(.semibold))

                Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func answerCard(_ answer: Answer) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(answer.questionText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(answer.value.isEmpty ? "No answer" : answer.value)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            session: Session(
                formId: "short_check_in",
                formTitle: "Short Check-In",
                answers: [
                    Answer(
                        questionId: "current_focus",
                        questionText: "What are you trying to move forward?",
                        value: "Finish the first native app pass."
                    ),
                    Answer(
                        questionId: "stuck_level",
                        questionText: "How stuck do you feel right now?",
                        value: "2"
                    )
                ]
            )
        )
    }
}
