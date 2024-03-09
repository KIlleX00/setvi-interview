import Combine
import SwiftUI

/// A view model responsible for managing data related to a list of repositories associated with a user.
class RepositoryListViewModel: ObservableObject {

    // MARK: - Output
    
    /// The list of repositories associated with the user.
    @Published var repositories = [RepositoryItem]()
    /// The list of organizations associated with the user.
    @Published var organizations = [Organization]()
    /// A boolean value indicating whether the view model is currently fetching the first page of repositories.
    @Published var isFetchingFirstPage = false
    
    let user: UserItem
    
    let alertViewModel = AlertViewModel()
    
    // MARK: - Properties
    
    private let cancellables = CompositeCancellable()
    private let gitHubApi: GitHubApi
    
    /// The task responsible for fetching data. It's being used to cancel ongoing task if we need to fetch fresh data.
    private var fetchTask: Task<Void, Never>?
    /// A boolean value indicating whether the view model is currently fetching the next page of repositories.
    private var isFetchingNextPage = false
    
    /// The response containing repositories fetched from the GitHub API.
    private var repositoriesResponse: RestResponse<[RepositoryItem], GitHubResponseHeaders>?
    
    // MARK: - Lifecycle
    
    init(user: UserItem, gitHubApi: GitHubApi) {
        self.user = user
        self.gitHubApi = gitHubApi
        
        fetchFirstPage()
    }
    
    deinit {
        cancellables.cancel()
    }
    
    // MARK: - Actions
    
    /// Fetches the next page of repositories if the current repository is one of the last 10 visible items.
    /// - Parameter repository: Repository that was last displayed in the list.
    func fetchNextPageIfNeeded(currentRepository repository: RepositoryItem) {
        guard let index = repositories.firstIndex(where: { $0.id == repository.id }),
              index >= repositories.count - 10 else { return }
        // Fetch next page only when one of the last 10 items is visible to the user.
        fetchNextPageOfUsers()
        
    }
    
    // MARK: - Data fetch
    
    /// Fetches the first page of repositories and fetch organizatinos for current user..
    private func fetchFirstPage() {
        isFetchingFirstPage = true
        fetchTask?.cancel()
        isFetchingNextPage = false
        let user = user
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                async let asyncRepositoriesResponse = gitHubApi.repositories(for: user.login, pageSize: 30)
                async let asyncOrganizationsResponse = gitHubApi.organizations(for: user.login, pageSize: 100)
                let repositoriesResponse = try await asyncRepositoriesResponse
                let organizationsResponse = try await asyncOrganizationsResponse
                guard !Task.isCancelled else { return }
                self.repositoriesResponse = repositoriesResponse
                self.repositories = repositoriesResponse.content
                self.organizations = organizationsResponse.content
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
              let previousResponse = repositoriesResponse,
              previousResponse.headers.hasNextPageLink else { return }
        isFetchingNextPage = true
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let repositoriesResponse = try await gitHubApi.nextPage(for: previousResponse)
                guard !Task.isCancelled else { return }
                self.repositoriesResponse = repositoriesResponse
                self.repositories += repositoriesResponse.content
            } catch {
                guard !Task.isCancelled else { return }
                self.alertViewModel.showAlert(for: error)
            }
            self.isFetchingNextPage = false
        }
    }
    
}

extension RepositoryItem: Identifiable { }
