import Foundation

/// A data structure representing GitHub API response headers.
/// This structure parses HTTP headers from GitHub API responses, specifically the "Link" header (used for pagination), to extract links and their relations. It provides a convenient way to access these links, such as determining the presence of a next page link.
struct GitHubResponseHeaders: HTTPResponseHeadersDecodable {
    
    private static let linksRegex = /<(?<url>.+?)>;\s?rel="(?<relation>\w+?)"/
    
    /// Regular expression pattern used to extract links and their relations from the "Link" header.
    let links: [LinkRelation : String]
    
    /// A Boolean value indicating whether there is a next page link available.
    var hasNextPageLink: Bool { links[.next] != nil }
    
    init(headers: [AnyHashable : Any]) {
        var linksByRelation = [LinkRelation : String]()
        
        // The "Link" header string contains one or more comma-separated links, each with a URL and a relation. This method splits the string by comma to separate individual links and iterates over them. For each link, it attempts to match the URL and relation using the `linksRegex` regular expression pattern.
        if let links = headers["Link"] as? String {
            for link in links.components(separatedBy: ",") {
                guard let match = try? GitHubResponseHeaders.linksRegex.firstMatch(in: link),
                      let relation = LinkRelation(rawValue: String(match.relation)) else { continue }
                linksByRelation[relation] = String(match.url)
            }
        }
        
        links = linksByRelation
    }
    
    enum LinkRelation: String, Hashable {
        case first
        case last
        case next
        case prev
    }
    
}

/// A data model representing a list of users retrieved from the GitHub API by search.
struct UsersSearchResponse: Codable {
    let items: [UserItem]
}

/// A data model representing a user retrieved from the GitHub API.
struct UserItem: Codable {
    let id: Int
    let login: String
    let avatarUrl: URL
}

/// A data model representing a organization retrieved from the GitHub API.
struct Organization: Codable {
    let id: Int
    let login: String
}

/// A data model representing a repository retrieved from the GitHub API.
struct RepositoryItem: Codable {
    let id: Int
    let name: String
    let language: String?
    let stargazersCount: Int
}

/// A data model representing a commit retrieved from the GitHub API.
struct CommitItem: Codable {
    let sha: String
    let commit: Commit
    let author: UserItem?
    let committer: UserItem?
    
    struct Commit: Codable {
        let message: String
    }
}
