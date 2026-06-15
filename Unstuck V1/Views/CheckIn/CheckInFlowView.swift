import SwiftUI

struct CheckInFlowView: View {
    let form: FormDefinition

    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var answers: [String: String] = [:]
    @State private var isShowingSummary = false
    @State private var isComplete = false

    private var currentQuestion: FormQuestion? {
        guard form.questions.indices.contains(currentQuestionIndex) else {
            return nil
        }

        return form.questions[currentQuestionIndex]
    }

    private var isFirstQuestion: Bool {
        currentQuestionIndex == 0
    }

    private var isFinalQuestion: Bool {
        currentQuestionIndex == form.questions.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            if isComplete {
                completionView
            } else {
                questionFlow
            }
        }
        .background(AppTheme.screenBackground)
        .navigationTitle(form.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingSummary) {
            SessionSummaryView(
                form: form,
                answers: answers,
                onSaved: {
                    isComplete = true
                }
            )
        }
    }

    private var questionFlow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            progressHeader

            if let currentQuestion {
                questionView(for: currentQuestion)
            }

            Spacer(minLength: AppTheme.Spacing.large)
            navigationControls
        }
        .padding(AppTheme.Spacing.large)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Question \(currentQuestionIndex + 1) of \(form.questions.count)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(form.questions.count))
                .tint(Color(red: 0.18, green: 0.42, blue: 0.90))
        }
    }

    @ViewBuilder
    private func questionView(for question: FormQuestion) -> some View {
        switch question.type {
        case .rating:
            RatingQuestionView(
                question: question,
                selectedValue: binding(for: question)
            )
        case .singleChoice:
            ChoiceQuestionView(
                question: question,
                selectedValue: binding(for: question)
            )
        case .text:
            TextQuestionView(
                question: question,
                text: binding(for: question)
            )
        }
    }

    private var navigationControls: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Button("Back") {
                goBack()
            }
            .buttonStyle(CheckInSecondaryButtonStyle())
            .disabled(isFirstQuestion)

            Button(isFinalQuestion ? "Complete" : "Next") {
                advance()
            }
            .buttonStyle(CheckInPrimaryButtonStyle())
        }
    }

    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppTheme.primaryGradient)

            VStack(spacing: AppTheme.Spacing.small) {
                Text("Check-In Saved")
                    .font(.title2.weight(.semibold))

                Text("Your session was saved on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(CheckInPrimaryButtonStyle())

            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }

    private func binding(for question: FormQuestion) -> Binding<String> {
        Binding(
            get: {
                answers[question.id, default: ""]
            },
            set: { newValue in
                answers[question.id] = newValue
            }
        )
    }

    private func goBack() {
        guard !isFirstQuestion else {
            return
        }

        currentQuestionIndex -= 1
    }

    private func advance() {
        guard isFinalQuestion else {
            currentQuestionIndex += 1
            return
        }

        isShowingSummary = true
    }

}

struct RatingQuestionView: View {
    let question: FormQuestion
    @Binding var selectedValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            Text(question.prompt)
                .font(.title2.weight(.semibold))

            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selectedValue = String(rating)
                    } label: {
                        Text("\(rating)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(RatingButtonStyle(isSelected: selectedValue == String(rating)))
                }
            }
        }
        .unstuckCardStyle()
    }
}

struct ChoiceQuestionView: View {
    let question: FormQuestion
    @Binding var selectedValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            Text(question.prompt)
                .font(.title2.weight(.semibold))

            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(question.options ?? [], id: \.self) { option in
                    Button {
                        selectedValue = option
                    } label: {
                        HStack {
                            Text(option)
                                .font(.headline)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: selectedValue == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedValue == option ? AppTheme.primaryGradient : LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(ChoiceButtonStyle(isSelected: selectedValue == option))
                }
            }
        }
        .unstuckCardStyle()
    }
}

struct TextQuestionView: View {
    let question: FormQuestion
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            Text(question.prompt)
                .font(.title2.weight(.semibold))

            TextField("Type your answer", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(4...8)
                .padding(AppTheme.Spacing.medium)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
        }
        .unstuckCardStyle()
    }
}

private struct CheckInPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(AppTheme.primaryGradient.opacity(configuration.isPressed ? 0.82 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

private struct CheckInSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(AppTheme.cardBackground.opacity(configuration.isPressed ? 0.72 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

private struct RatingButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                if isSelected {
                    AppTheme.primaryGradient
                } else {
                    Color(.tertiarySystemGroupedBackground)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1.0)
    }
}

private struct ChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(AppTheme.Spacing.medium)
            .background(isSelected ? Color(red: 0.18, green: 0.42, blue: 0.90).opacity(0.12) : Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous)
                    .stroke(isSelected ? Color(red: 0.18, green: 0.42, blue: 0.90) : .clear, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1.0)
    }
}

#Preview {
    NavigationStack {
        CheckInFlowView(form: SampleForms.shortCheckIn)
            .environmentObject(AuthService())
            .environmentObject(SessionStore())
            .environmentObject(StreakStore())
            .environmentObject(UserStatsStore())
            .environmentObject(AppearanceStore())
    }
}
