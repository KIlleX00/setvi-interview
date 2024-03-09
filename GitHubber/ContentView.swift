import SwiftUI

struct ContentView: View {
    let gitHubApi: GitHubApi
    @State var firstUser: UserItem? = nil
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world! \(firstUser?.login ?? "No name")")
        }
        .padding()
        .onAppear(perform: {
            Task { @MainActor in
                do {
                    let users = try await gitHubApi.searchUsers(with: "tg-x", pageSize: 10)
                    guard let user = users.content.items.first else { return }
                    firstUser = user
                    debugPrint(user.login)
                    let repos = try await gitHubApi.repositories(for: user.login, pageSize: 2)
                    guard let repo = repos.content.first else { return }
                    debugPrint(repo.name)
                    let commits = try await gitHubApi.commits(user: user.login, repository: repo.name, pageSize: 10)
                    debugPrint(commits)
                    let orgs = try await gitHubApi.organizations(for: user.login, pageSize: 10)
                    debugPrint(orgs)
                } catch {
                    print(error)
                }
            }
        })
    }
}

#Preview {
    ContentView(gitHubApi: GitHubMockedApi())
}
