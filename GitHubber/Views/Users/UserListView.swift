import SwiftUI

/// A view for displaying a list of users.
struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.users) { user in
                NavigationLink(value: user) {
                    UserItemView(userItem: user)
                }.alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .onAppear(perform: {
                        viewModel.fetchNextPageIfNeeded(currentUser: user)
                    })
            }
            if viewModel.isFetchingNextPage {
                HStack {
                    Spacer()
                    ProgressView().id(UUID())
                    Spacer()
                }
            }
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
            .navigationDestination(for: UserItem.self, destination: { userItem in
                RepositoryListView(viewModel: viewModel.repositoryListViewModel(for: userItem))
            }).alert(viewModel: viewModel.alertViewModel)
            .animation(.easeIn, value: viewModel.users)
    }
}

#Preview {
    NavigationStack {
        UserListView(viewModel: UserListViewModel(gitHubApi: GitHubMockedApi()))
    }
}
