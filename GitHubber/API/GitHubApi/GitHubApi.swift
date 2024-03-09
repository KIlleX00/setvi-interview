import Foundation

protocol GitHubApi {
    /// Searches for users based on the provided query.
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - pageSize: The number of results per page.
    /// - Returns: A `RestResponse` object containing the search results and response headers.
    /// - Throws: An error if the search request fails.
    func searchUsers(with query: String, pageSize: Int) async throws -> RestResponse<UsersSearchResponse, GitHubResponseHeaders>
    
    /// Retrieves organizations for a specified user.
    ///
    /// - Parameters:
    ///   - user: The username for which organizations are to be retrieved.
    ///   - pageSize: The number of organizations per page.
    /// - Returns: A `RestResponse` object containing the organizations and response headers.
    /// - Throws: An error if the repositories request fails.
    func organizations(for user: String, pageSize: Int) async throws -> RestResponse<[Organization], GitHubResponseHeaders>
    
    /// Retrieves repositories for a specified user.
    ///
    /// - Parameters:
    ///   - user: The username for which repositories are to be retrieved.
    ///   - pageSize: The number of repositories per page.
    /// - Returns: A `RestResponse` object containing the repositories and response headers.
    /// - Throws: An error if the repositories request fails.
    func repositories(for user: String, pageSize: Int) async throws -> RestResponse<[RepositoryItem], GitHubResponseHeaders>
    
    /// Retrieves commits for a specified user's repository.
    ///
    /// - Parameters:
    ///   - user: The username who owns the repository.
    ///   - repository: The name of the repository.
    ///   - pageSize: The number of commits per page.
    /// - Returns: A `RestResponse` object containing the commits and response headers.
    /// - Throws: An error if the commits request fails.
    func commits(user: String, repository: String, pageSize: Int) async throws -> RestResponse<[CommitItem], GitHubResponseHeaders>
    
    /// Fetches the next page of results based on the previous response.
    ///
    /// - Parameter previousResponse: The previous response containing pagination information.
    /// - Returns: A `RestResponse` object containing the next page of results and response headers.
    /// - Throws: An error if the next page request fails or if the next page URL is missing.
    func nextPage<Content: Decodable>(for previousResponse: RestResponse<Content, GitHubResponseHeaders>) async throws -> RestResponse<Content, GitHubResponseHeaders>
}

class GitHubRestApi: GitHubApi, RestApi {
    
    // MARK: - Rest Client
    
    internal let urlSession = URLSession(configuration: .default)
    
    let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    let jsonEncoder = JSONEncoder()
    
    // MARK: - Configuration
    
    private let baseUrl = "https://api.github.com/"
    
    // MARK: - Endpoints

    func searchUsers(with query: String, pageSize: Int = 30) async throws -> RestResponse<UsersSearchResponse, GitHubResponseHeaders> {
        let urlParams = [ "per_page" : "\(pageSize)",
                          "q" : query ]
        let request = try request(for: "search/users", urlParams: urlParams)
        return try await perform(request: request)
    }

    func organizations(for user: String, pageSize: Int = 30) async throws -> RestResponse<[Organization], GitHubResponseHeaders> {
        let urlParams = [ "per_page" : "\(pageSize)" ]
        let request = try request(for: "users/\(user)/orgs", urlParams: urlParams)
        return try await perform(request: request)
    }
    
    func repositories(for user: String, pageSize: Int = 30) async throws -> RestResponse<[RepositoryItem], GitHubResponseHeaders> {
        let urlParams = [ "per_page" : "\(pageSize)" ]
        let request = try request(for: "users/\(user)/repos", urlParams: urlParams)
        return try await perform(request: request)
    }
    
    func commits(user: String, repository: String, pageSize: Int = 30) async throws -> RestResponse<[CommitItem], GitHubResponseHeaders> {
        let urlParams = [ "per_page" : "\(pageSize)" ]
        let request = try request(for: "repos/\(user)/\(repository)/commits", urlParams: urlParams)
        return try await perform(request: request)
    }

    func nextPage<Content: Decodable>(for previousResponse: RestResponse<Content, GitHubResponseHeaders>) async throws -> RestResponse<Content, GitHubResponseHeaders> {
        guard let nextPageUrl = previousResponse.headers.links[.next] else { throw GitHubApiError.nextPageMissing }
        let request = try request(url: nextPageUrl)
        return try await perform(request: request)
    }
    
    // MARK: - Constructing URL Request
    
    internal func request(for path: String, method: HTTPMethod = .get, urlParams: [String : String] = [:], body: Data? = nil) throws -> URLRequest {
        try request(url: "\(baseUrl)\(path)", method: method, urlParams: urlParams, body: body)
    }
    
    private func request(url: String, method: HTTPMethod = .get, urlParams: [String : String] = [:], body: Data? = nil) throws -> URLRequest {
        // Initialize URLComponenets from given url string. If this fails, we will throw invalidUrl error.
        guard var urlComponents = URLComponents(string: url) else { throw GitHubApiError.invalidUrl }
        
        // To existing queryItems, append queryItems from url parameters.
        var queryItems = urlComponents.queryItems ?? []
        queryItems += urlParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = method.rawValue
        // Don't set http body for GET http method.
        if method != .get {
            urlRequest.httpBody = body
        }
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        return urlRequest
    }
    
    // MARK: - Error handling
    
    func extractError(from data: Data) -> (any Error)? {
        guard let gitHubError = try? jsonDecoder.decode(GitHubError.self, from: data) else { return nil }
        return GitHubApiError.requestFailed(message: gitHubError.message)
    }
    
}

/// An enumeration representing errors specific to the GitHub API.
enum GitHubApiError: Error {
    /// An error indicating that the URL initialization failed.
    case invalidUrl
    /// An error indicating that the next page URL is missing in the response headers.
    case nextPageMissing
    /// An error indicating that error has been returned by GitHub API.
    case requestFailed(message: String)
}

/// A mock implementation of the `GitHubApi` protocol for testing purposes.
class GitHubMockedApi: GitHubApi {
    
    static let exampleUser = UserItem(id: 1, login: "Pera", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!)
    
    func searchUsers(with query: String, pageSize: Int) async throws -> RestResponse<UsersSearchResponse, GitHubResponseHeaders> {
        let userItems = [ UserItem(id: 1, login: "Pera", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!),
                          UserItem(id: 2, login: "Dule", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!),
                          UserItem(id: 3, login: "Dusan", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!),
                          UserItem(id: 4, login: "Nikola", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!) ]
        return .init(headers: .init(headers: .init()), content: .init(items: userItems))
    }
    
    func organizations(for user: String, pageSize: Int) async throws -> RestResponse<[Organization], GitHubResponseHeaders> {
        return .init(headers: .init(headers: .init()), content: [.init(id: 1, login: "Setvi")])
    }
    
    func repositories(for user: String, pageSize: Int) async throws -> RestResponse<[RepositoryItem], GitHubResponseHeaders> {
        let repoItems = [ RepositoryItem(id: 1, name: "Setvi-iOS", language: "Swift", stargazersCount: 1000),
                          RepositoryItem(id: 2, name: "SwiftUI", language: "Swift", stargazersCount: 23),
                          RepositoryItem(id: 3, name: "Swift", language: "Swift", stargazersCount: 0),
                          RepositoryItem(id: 4, name: "SPM", language: "Swift", stargazersCount: 345),
                          RepositoryItem(id: 5, name: "ReactiveSwift", language: "Swift", stargazersCount: 123),
                          RepositoryItem(id: 6, name: "UIKit", language: "Objective-C", stargazersCount: 6),
                          RepositoryItem(id: 7, name: "Some random long name for repo", language: "C", stargazersCount: 3) ]
        return .init(headers: .init(headers: .init()), content: repoItems)
    }
    
    func commits(user: String, repository: String, pageSize: Int) async throws -> RestResponse<[CommitItem], GitHubResponseHeaders> {
        let user1 = UserItem(id: 1, login: "Pera", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!)
        let user2 = UserItem(id: 2, login: "Dule", avatarUrl: .init(string: "https://avatars.githubusercontent.com/u/11722390?v=4")!)
        let commitItems = [ CommitItem(sha: "e0ab8c4e18baf6679a65b325155923276b832687", commit: .init(message: "Commit 1"), author: user1, committer: user2),
                            CommitItem(sha: "0b73456e29b1cec2ab4bd032a6a98779bbd57d61", commit: .init(message: "Commit 1"), author: user2, committer: user2),
                            CommitItem(sha: "a9cf4550d5b57c9bc0f04a8c54a33e041a378fb4", commit: .init(message: "Commit 1"), author: user1, committer: user1),
                            CommitItem(sha: "37cc3c1b1575ce3f1f43ca1ffa84ca8bcd41c057", commit: .init(message: "Commit 1"), author: user2, committer: user1),
                            CommitItem(sha: "52324728cd02a2466b70a5b7c35bff9033cc81b1", commit: .init(message: "Commit 1"), author: user1, committer: nil),
                            CommitItem(sha: "3d3ed05bed71f19999db2207c714dab0028d37be", commit: .init(message: "Commit 1"), author: nil, committer: user2) ]
        return .init(headers: .init(headers: .init()), content: commitItems)
    }
    
    func nextPage<Content>(for previousResponse: RestResponse<Content, GitHubResponseHeaders>) async throws -> RestResponse<Content, GitHubResponseHeaders> where Content : Decodable {
        throw GitHubApiError.nextPageMissing
    }
    
}
