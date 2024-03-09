import SwiftUI

/// A view for displaying information about a user in a list.
struct UserItemView: View {
    let userItem: UserItem
    
    var body: some View {
        HStack {
            UserAvatarView(userItem: userItem, width: 36)
            Text(userItem.login)
        }
        .padding([.top, .bottom], 4)
    }
}

#Preview {
    UserItemView(userItem: GitHubMockedApi.exampleUser)
}
