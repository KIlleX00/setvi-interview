import Combine

/// A composite cancellable object that can manage multiple cancellable subscriptions.
class CompositeCancellable: Cancellable {
    
    /// The collection of cancellable subscriptions.
    private var cancellables = [AnyCancellable]()
    
    /// Cancels all the cancellable subscriptions.
    func cancel() {
        cancellables.forEach { $0.cancel() }
    }
    
    /// Adds a cancellable subscription to the composite cancellable.
    ///
    /// - Parameters:
    ///   - lhs: The composite cancellable to which the subscription will be added.
    ///   - rhs: The cancellable subscription to be added.
    static func +=(lhs: CompositeCancellable, rhs: AnyCancellable) {
        lhs.cancellables.append(rhs)
    }
    
}

