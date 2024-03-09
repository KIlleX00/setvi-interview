import SwiftUI

/// A view for displaying repository item list row.
struct RepositoryItemView: View {
    let repository: RepositoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repository.name)
                .font(.title3)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(repository.stargazersCount)")
                        .foregroundStyle(.secondary)
                }
                
                if let language = repository.language {
                    HStack(spacing: 4) {
                        if let color = UIColor.colorByLanguange[language] {
                            Color(uiColor: color)
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.gray, lineWidth: 1))
                        }
                        
                        Text(language)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    RepositoryItemView(repository: GitHubMockedApi.exampleRepository)
}
