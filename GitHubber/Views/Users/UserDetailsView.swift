import SwiftUI

/// A view for displaying details of a user, including their avatar, login, and associated organizations.
struct UserDetailsView: View {
    let userItem: UserItem
    let organizations: [Organization]
    
    var organizationsDescription: String {
        organizations.map({ $0.login }).joined(separator: ", ")
    }
    
    var body: some View {
        VStack {
            UserAvatarView(userItem: userItem, width: 150)
            Text(userItem.login)
                .font(.largeTitle)
            if !organizations.isEmpty {
                Text("Organizations: ")
                + Text(organizationsDescription)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    UserDetailsView(userItem: GitHubMockedApi.exampleUser, organizations: GitHubMockedApi.exampleOrgs)
}
