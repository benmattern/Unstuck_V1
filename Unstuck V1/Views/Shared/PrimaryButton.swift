import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?

    init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            if let systemImage {
                Image(systemName: systemImage)
            }

            Text(title)
                .font(.headline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(AppTheme.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

#Preview {
    PrimaryButton("Start Short Check-In", systemImage: "arrow.up.circle.fill")
        .padding()
}
