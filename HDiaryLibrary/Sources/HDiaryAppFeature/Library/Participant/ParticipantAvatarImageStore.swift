#if os(iOS)
  import UIKit

  final class ParticipantAvatarImageStore {
    static let shared = ParticipantAvatarImageStore()

    final class Entry {
      let image: UIImage?
      let maxPixelSize: Int

      init(image: UIImage?, maxPixelSize: Int) {
        self.image = image
        self.maxPixelSize = maxPixelSize
      }
    }

    private let cache = NSCache<NSData, Entry>()
    private let decode: @MainActor (Data, Int) async -> UIImage?

    init(decode: @escaping @MainActor (Data, Int) async -> UIImage? = { data, size in
      await ParticipantAvatarImage.decode(data, maxPixelSize: size)
    }) {
      self.decode = decode
      cache.countLimit = 200
      cache.totalCostLimit = 32 * 1024 * 1024
    }

    func cachedImage(for data: Data, maxPixelSize: Int) -> Entry? {
      guard let entry = cache.object(forKey: data as NSData),
            entry.image == nil || entry.maxPixelSize >= maxPixelSize
      else { return nil }
      return entry
    }

    func image(for data: Data, maxPixelSize: Int) async throws -> Entry {
      try Task.checkCancellation()
      if let cached = cachedImage(for: data, maxPixelSize: maxPixelSize) {
        return cached
      }

      let image = await decode(data, maxPixelSize)
      // A cancelled decode can return nil; it must not become a cached placeholder.
      try Task.checkCancellation()
      if let cached = cachedImage(for: data, maxPixelSize: maxPixelSize) {
        return cached
      }

      let entry = Entry(image: image, maxPixelSize: maxPixelSize)
      let bitmapCost = image?.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
      cache.setObject(entry, forKey: data as NSData, cost: data.count + bitmapCost)
      return entry
    }
  }
#endif
