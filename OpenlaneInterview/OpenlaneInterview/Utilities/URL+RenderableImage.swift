import Foundation

extension URL {
    var renderableImageURL: URL {
        guard host == "placehold.co", pathExtension.isEmpty else {
            return self
        }

        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.path += ".png"
        return components?.url ?? self
    }
}
