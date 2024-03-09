import Combine
import SwiftUI

/// A view model for managing user data and interactions in the user list view.
class UserListViewModel: ObservableObject {
    
    // MARK: - Input
    
    /// The search text entered by the user.
    @Published var searchText = ""
    
    // MARK: - Output
    
    /// The list of users to be displayed.
    @Published var users = [UserItem]()
    /// Indicates whether the first page of users is currently being loaded.
    @Published var isLoadingFirstPage = false
    /// Indicates whether the empty state view is hidden.
    @Published var isEmptyStateViewHidden = true
    /// The title of the empty state view.
    @Published var emptyStateTitle = ""
    /// The description of the empty state view.
    @Published var emptyStateDescription = ""
    
    let alertViewModel = AlertViewModel()
    
    // MARK: - Properties
    
    private let cancellables = CompositeCancellable()
    private let gitHubApi: GitHubApi
    
    private var searchTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?
    private var isFetchingNextPage = false
    
    private var response: RestResponse<UsersSearchResponse, GitHubResponseHeaders>?
    
    // MARK: - Lifecycle
    
    init(gitHubApi: GitHubApi) {
        self.gitHubApi = gitHubApi
        
        cancellables +=  $users.combineLatest($isLoadingFirstPage)
            .map({ !$0.isEmpty || $1 })
            .assign(to: \.isEmptyStateViewHidden, on: self)
        
        cancellables +=  $searchText.map({ $0.isEmpty ? "Enter a search query" : "Users not found" })
            .assign(to: \.emptyStateTitle, on: self)
        
        cancellables +=  $searchText.map({ $0.isEmpty ? "Start typing to search for users" : "Please try a different search query" })
            .assign(to: \.emptyStateDescription, on: self)
        
        cancellables += $searchText.handleEvents(receiveOutput: { [weak self] searchText in
            guard !searchText.isEmpty else { return }
            self?.isLoadingFirstPage = true
        }).debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.fetchFirstPageOfUsers() }
    }
    
    deinit {
        cancellables.cancel()
    }
    
    // MARK: - Actions
    
    /// Fetches the next page of users if the current user is one of the last 10 visible items.
        /// - Parameter user: User that was alst displayed in the list.
    func fetchNextPageIfNeeded(currentUser user: UserItem) {
        guard let index = users.firstIndex(where: { $0.id == user.id }),
              index >= users.count - 10 else { return }
        // Fetch next page only when one of the last 10 items is visible to the user.
        fetchNextPageOfUsers()
        
    }
    
    // MARK: - Data source
    
    func repositoryListViewModel(for user: UserItem) -> RepositoryListViewModel {
        RepositoryListViewModel(user: user, gitHubApi: gitHubApi)
    }
    
    // MARK: - Data fetch
    
    /// Fetches the first page of users based on the current search text.
    private func fetchFirstPageOfUsers() {
        isLoadingFirstPage = true
        searchTask?.cancel()
        nextPageTask?.cancel()
        isFetchingNextPage = false
        let searchText = searchText
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if searchText.isEmpty {
                self.response = nil
                self.users = []
            } else {
                do {
                    let response = try await gitHubApi.searchUsers(with: searchText, pageSize: 30)
                    guard !Task.isCancelled else { return }
                    self.response = response
                    self.users = response.content.items
                } catch {
                    guard !Task.isCancelled else { return }
                    self.alertViewModel.showAlert(for: error)
                }
            }
            self.isLoadingFirstPage = false
        }
    }
    
    /// Fetches the next page of users if available.
    private func fetchNextPageOfUsers() {
        guard isLoadingFirstPage == false,
              !isFetchingNextPage,
              let previousResponse = response,
              previousResponse.headers.hasNextPageLink else { return }
        isFetchingNextPage = true
        nextPageTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let response = try await gitHubApi.nextPage(for: previousResponse)
                guard !Task.isCancelled else { return }
                self.response = response
                self.users += response.content.items
            } catch {
                guard !Task.isCancelled else { return }
                self.alertViewModel.showAlert(for: error)
            }
            self.isFetchingNextPage = false
        }
    }
    
}

extension UserItem: Identifiable { }
