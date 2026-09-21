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

/// Uzak görsel. Önbellekteki görsel ilk karede çizilir: tembel listede ekrana geri dönen satır yer tutucudan
/// görsele sıçramaz. Boyutu çağıran belirler; kart sabit oranlı bir kutu verir, böylece yükleme boyu değiştirmez.
struct CachedRemoteImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var failed = false

    init(url: URL) {
        self.url = url
        _image = State(initialValue: RemoteImageCache.shared.image(for: url))
    }

    var body: some View {
        ZStack {
            AppTheme.color.bg.surfaceSunken
            if let image {

                Image(uiImage: image).resizable().scaledToFill()
            } else if failed {

                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.color.content.tertiary)
                    .accessibilityLabel(Text("community.imageUnavailable"))
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        guard image == nil else { return }
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
            // Satır ekrandan çıkınca yükleme iptal edilir; bu bir hata değildir, geri dönünce yeniden denenir.
            if !AppError.isCancellation(error) { failed = true }
        }
    }
}
