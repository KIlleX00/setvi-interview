import SwiftUI

/// A view for displaying a user's avatar image.
struct UserAvatarView: View {
    @Environment(\.displayScale) var scale
    
    /// The user item containing information about the user.
    let userItem: UserItem
    /// The width of the avatar image.
    let width: Double
    
    var body: some View {
        CachedAsyncImage(url: userItem.avatarUrl(for: width, scale: scale)) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.gray)
        }.frame(width: width, height: width)
            .clipShape(Circle())
            .overlay(Circle().stroke(.gray, lineWidth: 1))
    }
}

#Preview {
    UserAvatarView(userItem: GitHubMockedApi.exampleUser, width: 40)
}
