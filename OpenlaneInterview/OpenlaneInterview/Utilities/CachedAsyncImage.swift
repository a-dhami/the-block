import SwiftUI

private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 250
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var failureIconSize: CGFloat = 20

    @State private var state: LoadState = .loading

    private enum LoadState {
        case loading, loaded(UIImage), failed
    }

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)

            switch state {
            case .loading:
                ProgressView()
                    .scaleEffect(0.7)
            case let .loaded(image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            case .failed:
                Image(systemName: "car.fill")
                    .font(.system(size: failureIconSize))
                    .foregroundStyle(.secondary)
            }
        }
        .clipped()
        .task(id: url) {
            state = .loading

            // In UI tests we skip the network entirely and render the placeholder.
            // Otherwise ongoing image requests keep the app from going idle and the
            // tests stall, besides making them depend on network access.
            if ProcessInfo.processInfo.arguments.contains("-uitesting") {
                state = .failed
                return
            }

            guard let url else {
                state = .failed
                return
            }

            if let cached = ImageCache.shared.image(for: url) {
                state = .loaded(cached)
                return
            }

            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data)
            else {
                state = .failed
                return
            }

            ImageCache.shared.store(image, for: url)
            withAnimation(.easeIn(duration: 0.15)) {
                state = .loaded(image)
            }
        }
    }
}

#if DEBUG
#Preview {
    CachedAsyncImage(url: nil, failureIconSize: 36)
        .frame(width: 140, height: 100)
}
#endif
