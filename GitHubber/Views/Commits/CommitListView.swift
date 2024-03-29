import SwiftUI

/// A view responsible for displaying a list of commits associated with a repository.
struct CommitListView: View {
    @StateObject var viewModel: CommitListViewModel
    
    var body: some View {
        List {
            Section("Repository") {
                RepositoryItemView(repository: viewModel.repository)
            }

            if !viewModel.commits.isEmpty {
                Section("Commits") {
                    ForEach(viewModel.commits) { commit in
                        CommitItemView(commitItem: commit)
                            .onAppear(perform: {
                                viewModel.fetchNextPageIfNeeded(currentCommit: commit)
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
            .navigationTitle(viewModel.repository.name)
            .alert(viewModel: viewModel.alertViewModel)
            .animation(.easeIn, value: viewModel.commits)
    }
}

#Preview {
    NavigationStack {
        CommitListView(viewModel: CommitListViewModel(user: GitHubMockedApi.exampleUser, repository: GitHubMockedApi.exampleRepository, gitHubApi: GitHubMockedApi()))
    }
}
