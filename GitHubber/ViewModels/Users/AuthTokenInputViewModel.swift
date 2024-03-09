import Combine
import SwiftUI

/// View model for managing the input of GitHub personal access tokens.
class AuthTokenInputViewModel: ObservableObject {
    
    // MARK: - Input
    
    @Published var authToken = TokenStore.shared.authorizationToken ?? ""
    
    // MARK: - Output
    
    @Published var isSaveButtonDisabled = true
    
    let learnMoreUrl = URL(string: "https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens")
    
    // MARK: - Properties
    
    private let cancellables = CompositeCancellable()
    
    // MARK: - Lifecycle
    
    init() {
        cancellables += $authToken.map({ $0.isEmpty })
            .assign(to: \.isSaveButtonDisabled, on: self)
    }
    
    deinit {
        cancellables.cancel()
    }
    
    // MARK: - Actions
    
    func saveToken() {
        TokenStore.shared.authorizationToken = authToken
    }
    
}

