import SwiftUI
import UIKit

private final class RemoteImageCache: @unchecked Sendable {
    static let shared = RemoteImageCache()
    private let storage = NSCache<NSURL, UIImage>()

    private init() {
        storage.countLimit = 80
        storage.totalCostLimit = 32 * 1024 * 1024
    }

    func image(for url: URL) -> UIImage? { storage.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL, cost: Int) {
        storage.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

struct CachedRemoteImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else if failed {
                EchoEmptyState("community.imageUnavailable", systemImage: "photo")
            } else {
                EchoSkeleton(height: 180)
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        if let cached = RemoteImageCache.shared.image(for: url) {
            image = cached
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let loaded = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            RemoteImageCache.shared.insert(loaded, for: url, cost: data.count)
            image = loaded
        } catch {
            failed = true
        }
    }
}
