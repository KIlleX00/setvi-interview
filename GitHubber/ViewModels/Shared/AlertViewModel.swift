import Foundation

/// Represents an action for displaying an alert.
struct AlertAction {
    /// A predefined alert action with the title "Ok" and no handler.
    static let okAction = AlertAction(title: "Ok", handler: nil)
    
    /// The title of the action.
    let title: String
    /// The handler closure to be executed when the action is triggered.
    let handler: (() -> Void)?
}

extension AlertAction: Identifiable {
    var id: String { title }
}

/// A view model for managing alerts in SwiftUI.
class AlertViewModel: ObservableObject {
    
    // MARK: - Output
    
    /// Indicates whether the alert is presented/active.
    @Published var isActive = false
    /// The title of the alert.
    @Published var title = ""
    /// The message of the alert./
    @Published var message = ""
    /// The actions available in the alert.
    @Published var actions = [AlertAction]()
    
    // MARK: - Properties
    
    private let cancellables = CompositeCancellable()
    
    // MARK: - Lifecycle
 
    deinit {
        cancellables.cancel()
    }
    
    // MARK: - Update
    
    /// Shows an alert for the provided error.
    ///
    /// - Parameter error: The error for which the alert is shown.
    func showAlert(for error: Error) {
        if let error = error as? AlertableError {
            title = error.alertTitle
            message = error.alertMessage
        } else {
            title = "An error has occured"
            message = error.localizedDescription
        }
        actions = [.okAction]
        isActive = true
    }
    
}

/// A protocol for errors that can be displayed as alerts.
protocol AlertableError {
    
    var alertTitle: String { get }
    var alertMessage: String { get }
    
}

extension RestClientError: AlertableError {
    
    var alertTitle: String { "An error has occured" }
    
    var alertMessage: String {
        return switch self {
            case .generalErrorWithoutReason: "Please try again"
            case .generalError(let reason): reason
        }
    }
    
}

extension GitHubApiError: AlertableError {
    
    var alertTitle: String { "An error has occured" }
    
    var alertMessage: String {
        return switch self {
            case .invalidUrl: "Provided URL is not supported"
            case .nextPageMissing: "Failed to fetch next page of items"
            case .requestFailed(let message): message
        }
    }
    
}
