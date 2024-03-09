import SwiftUI

/// A view modifier for displaying alerts using an `AlertViewModel`.
struct AlertModifier: ViewModifier {
    @ObservedObject var viewModel: AlertViewModel
    
    func body(content: Content) -> some View {
        content
            .alert(viewModel.title, isPresented: $viewModel.isActive) {
                ForEach(viewModel.actions) { action in
                    Button(action: {
                        action.handler?()
                    }, label: {
                        Text(action.title)
                    })
                }
            } message: {
                Text(viewModel.message)
            }


    }
}

extension View {
    
    /// Manage alerts using the provided view model.
    ///
    /// - Parameter viewModel: The view model responsible for managing the alert state.
    /// - Returns: A modified view that displays alerts.
    func alert(viewModel: AlertViewModel) -> some View {
        modifier(AlertModifier(viewModel: viewModel))
    }
    
}
