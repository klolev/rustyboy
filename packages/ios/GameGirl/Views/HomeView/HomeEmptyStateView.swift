import SwiftUI

struct HomeEmptyStateView: View {
    let didPressAddGame: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Text("GAME GIRL")
                .font(.semiBoldItalic(56))
                .foregroundColor(.logo)

            Button(action: didPressAddGame) {
                Text("add_games")
                    .font(.semiBold(24))
                    .foregroundColor(.white)
            }
            .cornerRadius(5)
            .padding(.vertical, 24)
            .padding(.horizontal, 64)
            .background(Color.accentColor)
        }
    }
}
