import SwiftUI

/// A view representing an empty state with an image, title, and description.
///
/// This view is used to display a message when there is no content to show in a particular context.
/// It typically includes an image, a title, and a brief description explaining the empty state.
struct EmptyStateView: View {
    let image: Image
    let title: String
    let description: String
    
    var body: some View {
        VStack {
            image
                .font(.largeTitle)
            Text(title)
                .font(.title)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.gray)
                
        }
    }
}

#Preview {
    EmptyStateView(image: Image(systemName: "doc.text.magnifyingglass"), title: "Test title", description: "Test description of empty state view")
}
