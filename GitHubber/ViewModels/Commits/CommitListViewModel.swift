import Combine
import SwiftUI

/// A view model responsible for managing data related to a list of commits associated with a user and a repository.
class CommitListViewModel: ObservableObject {

    // MARK: - Output
    
    /// The list of commits associated with the user and the repository.
    @Published var commits = [CommitItem]()
    /// A boolean value indicating whether the view model is currently fetching the first page of commits.
    @Published var isFetchingFirstPage = false
    /// A boolean value indicating whether the view model is currently fetching the next page of commits.
    @Published var isFetchingNextPage = false
    
    let repository: RepositoryItem
    
    let alertViewModel = AlertViewModel()
    
    // MARK: - Properties
    
    private let cancellables = CompositeCancellable()
    private let gitHubApi: GitHubApi
    private let user: UserItem
    
    /// The task responsible for fetching data. It's being used to cancel ongoing task if we need to fetch fresh data.
    private var fetchTask: Task<Void, Never>?
    
    /// The response containing http headers and  commits  fetched from the GitHub API.
    private var commitsResponse: RestResponse<[CommitItem], GitHubResponseHeaders>?
    
    // MARK: - Lifecycle
    
    init(user: UserItem, repository: RepositoryItem, gitHubApi: GitHubApi) {
        self.repository = repository
        self.user = user
        self.gitHubApi = gitHubApi
        
        fetchFirstPage()
    }
    
    deinit {
        cancellables.cancel()
    }
    
    // MARK: - Actions
    
    /// Fetches the next page of commits if the current commit is one of the last 10 visible items.
        /// - Parameter commit: User that was alst displayed in the list.
    func fetchNextPageIfNeeded(currentCommit commit: CommitItem) {
        guard let index = commits.firstIndex(where: { $0.id == commit.id }),
              index >= commits.count - 10 else { return }
        // Fetch next page only when one of the last 10 items is visible to the user.
        fetchNextPageOfUsers()
        
    }
    
    // MARK: - Data fetch
    
    /// Fetches the first page of commits.
    private func fetchFirstPage() {
        isFetchingFirstPage = true
        fetchTask?.cancel()
        isFetchingNextPage = false
        let user = user
        let repo = repository
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let commitsResponse = try await gitHubApi.commits(user: user.login, repository: repo.name, pageSize: 30)
                guard !Task.isCancelled else { return }
                self.commitsResponse = commitsResponse
                self.commits = commitsResponse.content
            } catch {
                guard !Task.isCancelled else { return }
                self.alertViewModel.showAlert(for: error)
            }
            self.isFetchingFirstPage = false
        }
    }
    
    /// Fetches the next page of users if available.
    private func fetchNextPageOfUsers() {
        guard isFetchingFirstPage == false,
              !isFetchingNextPage,
              let previousResponse = commitsResponse,
              previousResponse.headers.hasNextPageLink else { return }
        isFetchingNextPage = true
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let commitsResponse = try await gitHubApi.nextPage(for: previousResponse)
                guard !Task.isCancelled else { return }
                self.commitsResponse = commitsResponse
                self.commits += commitsResponse.content
            } catch {
                guard !Task.isCancelled else { return }
                self.alertViewModel.showAlert(for: error)
            }
            self.isFetchingNextPage = false
        }
    }
    
}

extension CommitItem: Identifiable {
    var id: String { sha }
}
