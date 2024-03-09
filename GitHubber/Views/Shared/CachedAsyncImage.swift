import SwiftUI

/// A view that loads an image asynchronously from a URL and caches it.
///
/// Use `CachedAsyncImage` to display an image asynchronously from a URL with caching support. You can provide a content view and a placeholder view to be displayed while the image is being loaded.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        if let image = image {
            content(Image(uiImage: image))
        } else {
            placeholder()
                .onAppear(perform: loadImage)
        }
    }
    
    /// Initializes a `CachedAsyncImage` with a URL, content view, and placeholder view.
    /// - Parameters:
    ///   - url: The URL from which to load the image.
    ///   - content: A closure that provides the content view to display when the image is loaded.
    ///   - placeholder: A closure that provides the placeholder view to display while the image is being loaded.
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
        self.content = content
    }
    
    private func loadImage() {
        guard let url else { return }
        let request = URLRequest(url: url)
        
        // Check if we already have cached image
        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            self.image = UIImage(data: cachedResponse.data)
        } else {
            // If we don't have cached image, fetch one from provided URL.
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    URLCache.shared.storeCachedResponse(CachedURLResponse(response: response!, data: data), for: request)
                    DispatchQueue.main.async {
                        self.image = image
                    }
                }
            }.resume()
        }
    }
}
