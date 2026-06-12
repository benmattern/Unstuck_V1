import SwiftUI

struct SessionRowView: View {
    let session: Session

    private var firstAnswerPreview: String? {
        session.answers.first?.value
    }

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.primaryGradient)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(session.formTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let firstAnswerPreview, !firstAnswerPreview.isEmpty {
                        Text(firstAnswerPreview)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: AppTheme.Spacing.small)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    SessionRowView(
        session: Session(
            formId: "short_check_in",
            formTitle: "Short Check-In",
            answers: [
                Answer(
                    questionId: "current_focus",
                    questionText: "What are you trying to move forward?",
                    value: "Finish the first native app pass."
                )
            ]
        )
    )
    .padding()
    .background(AppTheme.screenBackground)
}
