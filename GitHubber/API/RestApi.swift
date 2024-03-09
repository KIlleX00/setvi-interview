import UIKit

/// A protocol defining a RESTful API client interface.
protocol RestApi {
    /// The URLSession used to perform network requests.
    var urlSession: URLSession { get }
    /// The JSONDecoder used for decoding JSON data from responses.
    var jsonDecoder: JSONDecoder { get }
    /// The JSONEncoder used for encoding data to JSON for requests.
    var jsonEncoder: JSONEncoder { get }
    
    /// Constructs a URLRequest for the given API path, HTTP method, query parameters, and request body.
    ///
    /// - Parameters:
    ///   - path: The path component of the API endpoint.
    ///   - method: The HTTP method for the request
    ///   - urlParams: The query parameters to be included in the URL.
    ///   - body: The request body data, if applicable.
    /// - Returns: A URLRequest instance representing the API request.
    /// - Throws: An error if URLRequest construction fails.
    func request(for path: String, method: HTTPMethod, urlParams: [String : String], body: Data?) throws -> URLRequest
    
    /// Extracts error information from response data, if available.
    /// This method analyzes the response data to determine if an error occurred during the request.
    /// If an error is found, it returns an Error object representing the error.
    func extractError(from data: Data) -> Error?
}

/// Extension providing default implementations for common tasks in a RestApi.
extension RestApi {
    
    // MARK: - Performing network tasks
    
   /// Performs a network request asynchronously and processes the response.
   ///
   /// - Parameters:
   ///   - request: The URLRequest to be executed.
   /// - Returns: A `RestResponse` object containing the decoded response content and headers.
   /// - Throws: An error if the network request fails or response processing encounters an error.
    func perform<Content: Decodable, Headers: HTTPResponseHeadersDecodable>(request: URLRequest) async throws -> RestResponse<Content, Headers> {
        let (data, response) = try await urlSession.data(for: request)
        if let error = checkForError(request: request, data: data, response: response) {
            throw error
        } else {
            return try processTaskResult(data: data, response: response)
        }
    }
    
    /// Processes the result of a network task, decoding the response data and extracting headers.
    ///
    /// - Parameters:
    ///   - data: The data received from the network response.
    ///   - response: The URLResponse received from the network request.
    /// - Returns: A `RestResponse` object containing the decoded response content and headers.
    /// - Throws: An error if response processing encounters an error.
    func processTaskResult<Content: Decodable, Headers: HTTPResponseHeadersDecodable>(data: Data, response: URLResponse) throws -> RestResponse<Content, Headers> {
        // Initialize headers from response.
        guard let response = response as? HTTPURLResponse else { throw RestClientError.generalError(reason: "Failed to decode server response.") }
        let headers = Headers(headers: response.allHeaderFields)
        
        if Content.self is String.Type, let text = String(data: data, encoding: .utf8) {
            // String is not a valid JSON. Because of that, we are handling it without JSON decoder.
            return RestResponse(headers: headers, content: text as! Content)
        } else {
            let content = try jsonDecoder.decode(Content.self, from: data)
            return RestResponse(headers: headers, content: content)
        }
    }
    
    // MARK: - Constructing URL Request
    
    /// Constructs a URLRequest with the given parameters and optional JSON body.
    ///
    /// - Parameters:
    ///   - path: The path component of the API endpoint.
    ///   - method: The HTTP method for the request (default is GET).
    ///   - urlParams: The query parameters to be included in the URL.
    ///   - json: The JSON object to be included in the request body (optional).
    /// - Returns: A URLRequest instance representing the API request.
    /// - Throws: An error if URLRequest construction fails.
    func request<T: Encodable>(for path: String, method: HTTPMethod = .get, urlParams: [String : String] = [:], json: T? = nil) throws -> URLRequest {
        var body: Data?
        if method != .get, let json = json {
            body = try? jsonEncoder.encode(json)
        }
        return try request(for: path, method: method, urlParams: urlParams, body: body)
    }
    
    /// Constructs a URLRequest with the given parameters and optional JSON parameters.
    ///
    /// - Parameters:
    ///   - path: The path component of the API endpoint.
    ///   - method: The HTTP method for the request (default is GET).
    ///   - urlParams: The query parameters to be included in the URL.
    ///   - jsonParams: The JSON parameters to be included in the request body (optional).
    /// - Returns: A URLRequest instance representing the API request.
    /// - Throws: An error if URLRequest construction fails.
    func request(for path: String, method: HTTPMethod = .get, urlParams: [String : String] = [:], jsonParams: Any? = nil) throws -> URLRequest {
        var body: Data?
        if method != .get, let jsonParams = jsonParams {
            body = try? JSONSerialization.data(withJSONObject: jsonParams, options: [])
        }
        return try request(for: path, method: method, urlParams: urlParams, body: body)
    }
    
    // MARK: - Error handling
    
    func extractError(from data: Data) -> Error? {
        return nil
    }
    
    /// Checks for network errors or error responses in the provided data and response.
    ///
    /// This method examines the response status code and data to determine if an error occurred during the request.
    ///
    /// - Parameters:
    ///   - request: The URLRequest for which the response is checked.
    ///   - data: The response data, if available.
    ///   - response: The URLResponse received from the network request.
    ///   - error: The error, if any, encountered during the network request.
    /// - Returns: An Error object
    func checkForError(request: URLRequest, data: Data?, response: URLResponse?, error: Error? = nil) -> Error? {
        if let error = error {
            return error
        } else if let data = data, let error = extractError(from: data) {
            return error
        }
 
        guard let response = response as? HTTPURLResponse,
              response.statusCode > 299 else { return nil }
        
        if let data = data {
            if let reason = String(data: data, encoding: .utf8) {
                return RestClientError.generalError(reason: reason)
            } else {
                return RestClientError.generalErrorWithoutReason
            }
        } else {
            return RestClientError.generalErrorWithoutReason
        }
    }
}

enum RestClientError: Error {
    case generalErrorWithoutReason
    case generalError(reason: String)
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// A protocol defining a type that can decode HTTP response headers.
///
/// Types conforming to this protocol can parse HTTP response headers
/// and initialize themselves with the decoded header information.
protocol HTTPResponseHeadersDecodable {
    init(headers: [AnyHashable : Any])
}

/// A generic structure representing a response from a RESTful API.
///
/// This structure contains both the decoded response content and
/// the decoded HTTP response headers.
struct RestResponse<Content: Decodable, Headers: HTTPResponseHeadersDecodable> {
    let headers: Headers
    let content: Content
}
