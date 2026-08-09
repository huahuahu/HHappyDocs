#if os(iOS)

  import Foundation
  import ImageIO
  import UniformTypeIdentifiers

  /// 将头像原图压缩为适合 Widget 存储与展示的小尺寸 JPEG。
  nonisolated enum WidgetAvatarThumbnailer {
    @concurrent
    static func thumbnailData(from data: Data?, maxPixelSize: Int) async -> Data? {
      guard let data, maxPixelSize > 0,
            let source = CGImageSourceCreateWithData(data as CFData, nil)
      else {
        return nil
      }

      let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
      ]
      guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
      }

      let output = NSMutableData()
      guard let destination = CGImageDestinationCreateWithData(
        output,
        UTType.jpeg.identifier as CFString,
        1,
        nil
      ) else {
        return nil
      }

      CGImageDestinationAddImage(
        destination,
        image,
        [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary
      )
      guard CGImageDestinationFinalize(destination) else {
        return nil
      }

      return output as Data
    }
  }

#endif
