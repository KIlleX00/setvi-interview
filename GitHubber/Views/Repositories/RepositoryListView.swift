import SwiftUI

/// A view for displaying a list of repositories associated with a user and details about user.
struct RepositoryListView: View {
    @StateObject var viewModel: RepositoryListViewModel
    
    var body: some View {
        List {
            Section("Details") {
                UserDetailsView(userItem: viewModel.user, organizations: viewModel.organizations)
                    .padding(8)
                    .listRowSeparator(.hidden)
            }
            
            if !viewModel.repositories.isEmpty {
                Section("Repositories") {
                    ForEach(viewModel.repositories) { repository in
                        NavigationLink(value: repository) {
                            RepositoryItemView(repository: repository)
                        }.onAppear(perform: {
                            viewModel.fetchNextPageIfNeeded(currentRepository: repository)
                        })
                    }
                    
                    if viewModel.isFetchingNextPage {
                        HStack {
                            Spacer()
                            ProgressView().id(UUID())
                            Spacer()
                        }
                    }
                }
            }
        }.overlay(content: {
            if viewModel.isFetchingFirstPage {
                ProgressView()
                    .scaleEffect(2)
                
            }
        }).navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.user.login)
            .navigationDestination(for: RepositoryItem.self, destination: { repository in
                CommitListView(viewModel: viewModel.commitListViewModel(for: repository))
            }).alert(viewModel: viewModel.alertViewModel)
            .animation(.easeIn, value: viewModel.repositories)
    }
}

#Preview {
    NavigationStack {
        RepositoryListView(viewModel: RepositoryListViewModel(user: GitHubMockedApi.exampleUser, gitHubApi: GitHubMockedApi()))
    }
}
