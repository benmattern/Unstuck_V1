import Foundation

enum SampleForms {
    static let shortCheckIn = FormDefinition(
        id: "short_check_in",
        title: "Short Check-In",
        description: "A quick reset when you need to get moving again.",
        questions: [
            FormQuestion(
                id: "current_focus",
                prompt: "What are you trying to move forward?",
                type: .text
            ),
            FormQuestion(
                id: "stuck_level",
                prompt: "How stuck do you feel right now?",
                type: .rating
            ),
            FormQuestion(
                id: "main_blocker",
                prompt: "What is the main blocker?",
                type: .singleChoice,
                options: [
                    "Unclear next step",
                    "Low energy",
                    "Avoidance",
                    "Too many options",
                    "External constraint"
                ]
            ),
            FormQuestion(
                id: "next_action",
                prompt: "What is the next small action?",
                type: .text
            ),
            FormQuestion(
                id: "ten_minute_action",
                prompt: "Can you do that in the next 10 minutes?",
                type: .singleChoice,
                options: [
                    "Yes",
                    "Not yet"
                ]
            )
        ]
    )

    static let mainForm = FormDefinition(
        id: "main_form",
        title: "Main Form",
        description: "A longer reflection session to help clarify direction and identify a next action.",
        questions: [
            FormQuestion(
                id: "current_situation",
                prompt: "What situation are you dealing with?",
                type: .text
            ),
            FormQuestion(
                id: "desired_outcome",
                prompt: "What outcome would you like to reach?",
                type: .text
            ),
            FormQuestion(
                id: "importance",
                prompt: "How important is this right now?",
                type: .rating
            ),
            FormQuestion(
                id: "confidence",
                prompt: "How confident are you that you can make progress?",
                type: .rating
            ),
            FormQuestion(
                id: "biggest_obstacle",
                prompt: "What is the biggest obstacle?",
                type: .singleChoice,
                options: [
                    "Lack of information",
                    "Lack of time",
                    "Low energy",
                    "Fear of failure",
                    "Competing priorities",
                    "Other"
                ]
            ),
            FormQuestion(
                id: "next_action",
                prompt: "What is the next concrete action you could take?",
                type: .text
            ),
            FormQuestion(
                id: "commitment",
                prompt: "Will you commit to taking that action?",
                type: .singleChoice,
                options: [
                    "Yes",
                    "Maybe",
                    "Not yet"
                ]
            )
        ]
    )
}
