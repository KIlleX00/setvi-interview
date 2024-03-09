import SwiftUI

/// A view for entering GitHub personal access tokens.
struct AuthTokenInputView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel = AuthTokenInputViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("GitHub Personal Access Token")
                    .font(.title)
                
                Text("To optimize your experience and mitigate the severe rate limitations enforced by the GitHub API for unauthenticated users, we highly recommend generating and inputting your personal access token. This action will notably enhance your rate limits, allowing for smoother and more efficient interactions with the GitHub platform.")
                    .font(.subheadline)
                
                if let learnMoreUrl = viewModel.learnMoreUrl {
                    Link("Learn more about Access Tokens", destination: learnMoreUrl)
                }
                
                TextField(text: $viewModel.authToken) {
                    Text("Access Token")
                }.textFieldStyle(.roundedBorder)
                
                Button {
                    viewModel.saveToken()
                    dismiss()
                } label: {
                    Text("Save Token")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }.buttonStyle(BorderedButtonStyle())
                    .disabled(viewModel.isSaveButtonDisabled)
                    
            }.padding()
        }
    }
}

#Preview {
    AuthTokenInputView()
}
