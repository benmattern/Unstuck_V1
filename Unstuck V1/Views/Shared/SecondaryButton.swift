import SwiftUI

struct SecondaryButton: View {
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
                    .foregroundStyle(AppTheme.primaryGradient)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(AppTheme.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.button, style: .continuous))
    }
}

#Preview {
    SecondaryButton("Past Sessions", systemImage: "clock")
        .padding()
        .background(AppTheme.screenBackground)
}
