import SwiftUI

struct AppCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

#Preview {
    AppCard {
        Text("Card")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .background(AppTheme.screenBackground)
}
