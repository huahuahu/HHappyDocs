#if os(iOS)
  import ImageIO
  import UIKit
  import UniformTypeIdentifiers

  nonisolated enum ParticipantAvatarImage {
    @concurrent
    static func decode(_ data: Data?, maxPixelSize: Int? = nil) async -> UIImage? {
      guard !Task.isCancelled,
            let data,
            let source = UIImage(data: data),
            let raster = source.cgImage,
            let decoded = visibleRaster(raster, maxPixelSize: maxPixelSize),
            !Task.isCancelled
      else { return nil }
      return UIImage(cgImage: decoded, scale: source.scale, orientation: source.imageOrientation)
    }

    @MainActor
    static func previewItem(for data: Data) -> HPreviewItem? {
      guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let identifier = CGImageSourceGetType(source),
            let type = UTType(identifier as String)
      else { return nil }

      // Quick Look gets the original bytes, never the downsampled avatar.
      let previewType: HPreviewItemType
      switch type {
      case .jpeg: previewType = .jpegImage
      case .png: previewType = .pngImage
      case .heic, .heif: previewType = .heicImage
      case .gif: previewType = .gif
      default:
        return UIImage(data: data).map(HPreviewItem.init)
      }
      return HPreviewItem(data: data, previewType: previewType)
    }

    private static func visibleRaster(_ image: CGImage, maxPixelSize: Int?) -> CGImage? {
      // Some legacy avatars have readable headers but draw entirely transparent.
      // Decode into a cleared bitmap and inspect alpha, keeping black and white artwork.
      let longestSide = max(image.width, image.height)
      let scale = min(1, CGFloat(max(1, maxPixelSize ?? longestSide)) / CGFloat(longestSide))
      let width = max(1, Int(CGFloat(image.width) * scale))
      let height = max(1, Int(CGFloat(image.height) * scale))
      guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
      ), let data = context.data else { return nil }

      let bounds = CGRect(x: 0, y: 0, width: width, height: height)
      context.clear(bounds)
      context.interpolationQuality = .high
      context.draw(image, in: bounds)
      let pixels = UnsafeBufferPointer(
        start: data.assumingMemoryBound(to: UInt8.self),
        count: context.bytesPerRow * context.height
      )
      guard stride(from: 3, to: pixels.count, by: 4).contains(where: { pixels[$0] != 0 }) else { return nil }
      return context.makeImage()
    }
  }
#endif
