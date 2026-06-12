import SwiftUI

struct PlaceholderScreenView: View {
    let title: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppTheme.primaryGradient)

            Text(title)
                .font(.title2.weight(.semibold))

            Text("This screen will be built in a later step.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.screenBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlaceholderScreenView(title: "Placeholder")
    }
}
