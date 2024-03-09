import SwiftUI

@main
struct GitHubberApp: App {
    
    let gitHubApi: GitHubApi
    
    init() {
        // Use mocked GitHubApi if we are running in a preview environment
        gitHubApi = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ? GitHubMockedApi() : GitHubRestApi()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                UserListView(viewModel: UserListViewModel(gitHubApi: gitHubApi))
            }
        }
    }
}
