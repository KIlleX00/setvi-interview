import SwiftUI

/// A view for displaying a list of users.
struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    
    var body: some View {
        List.init(viewModel.users) { user in
            UserItemView(userItem: user)
                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                .onAppear(perform: {
                    viewModel.fetchNextPageIfNeeded(currentUser: user)
                })
        }.overlay(content: {
            if !viewModel.isEmptyStateViewHidden {
                EmptyStateView(image: Image(systemName: "doc.text.magnifyingglass"), title: viewModel.emptyStateTitle, description: viewModel.emptyStateDescription)
            }
            
            if viewModel.isLoadingFirstPage {
                ProgressView()
                    .scaleEffect(2)
                
            }
        }).searchable(text: $viewModel.searchText)
            .autocorrectionDisabled()
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.inline)
            .alert(viewModel: viewModel.alertViewModel)
    }
}

#Preview {
    NavigationStack {
        UserListView(viewModel: UserListViewModel(gitHubApi: GitHubMockedApi()))
    }
}
