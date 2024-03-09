//
//  CommitItemView.swift
//  GitHubber
//
//  Created by Marek Sokol on 9.3.24..
//

import SwiftUI

/// A view displaying details of a commit.
struct CommitItemView: View {
    let commitItem: CommitItem
    
    private let primaryMessage: String
    private let secondaryMessage: String?
    
    var authorText: Text {
        var text = Text("")
        if let author = commitItem.author {
            text = text + Text(author.login) + Text(" authored").foregroundColor(.gray)
            if let committer = commitItem.committer, committer.id != author.id {
                text = text + Text(" and ").foregroundColor(.gray) + Text(committer.login) + Text(" committed").foregroundColor(.gray)
            }
        }
        return text
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(commitItem.sha)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(primaryMessage)
            if let secondaryMessage {
                Text(secondaryMessage)
                    .foregroundStyle(.secondary)
            }
            if let author = commitItem.author {
                HStack {
                    UserAvatarView(userItem: author, width: 16)
                    authorText
                }
            }
        }
    }
    
    init(commitItem: CommitItem) {
        self.commitItem = commitItem
        
        var messageComponenets = commitItem.commit.message
            .components(separatedBy: "\n")
            .filter({ !$0.isEmpty })
        
        if messageComponenets.isEmpty {
            primaryMessage = ""
        } else {
            primaryMessage = messageComponenets.removeFirst()
        }
        if messageComponenets.isEmpty {
            secondaryMessage = nil
        } else {
            secondaryMessage = messageComponenets.joined(separator: "\n")
        }
    }
}

#Preview {
    CommitItemView(commitItem: GitHubMockedApi.exampleCommit)
}
