#if os(iOS)
  import UIKit

  /// One transform for both the visible crop and the exported bitmap.
  struct HImageCropGeometry {
    let imageSize: CGSize
    let viewport: CGSize
    let scale: CGFloat
    let offset: CGSize

    init(imageSize: CGSize, viewport: CGSize, scale: CGFloat, offset: CGSize) {
      self.imageSize = imageSize
      self.viewport = viewport
      self.scale = min(max(scale, 1), 5)
      let factor = max(viewport.width / max(imageSize.width, 1), viewport.height / max(imageSize.height, 1)) * self.scale
      let limitX = max(0, (imageSize.width * factor - viewport.width) / 2)
      let limitY = max(0, (imageSize.height * factor - viewport.height) / 2)
      self.offset = CGSize(
        width: min(max(offset.width, -limitX), limitX),
        height: min(max(offset.height, -limitY), limitY)
      )
    }

    var imageFrame: CGRect {
      imageFrame(at: scale)
    }

    private func imageFrame(at scale: CGFloat) -> CGRect {
      let factor = max(viewport.width / max(imageSize.width, 1), viewport.height / max(imageSize.height, 1)) * scale
      let size = CGSize(width: imageSize.width * factor, height: imageSize.height * factor)
      return CGRect(
        x: (viewport.width - size.width) / 2 + offset.width,
        y: (viewport.height - size.height) / 2 + offset.height,
        width: size.width, height: size.height
      )
    }

    func render(_ image: UIImage) throws -> UIImage {
      guard image.size.width > 0, image.size.height > 0,
            image.cgImage != nil || image.ciImage != nil,
            viewport.width > 0, viewport.height > 0 else {
        throw CocoaError(.coderInvalidValue)
      }
      // Export a square/rectangular photo; avatar views apply the circular mask.
      // The white backing matches the preview for transparent source images.
      let factor = 512 / max(viewport.width, viewport.height)
      let output = CGSize(width: viewport.width * factor, height: viewport.height * factor)
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true
      return UIGraphicsImageRenderer(size: output, format: format).image { renderer in
        UIColor.white.setFill()
        renderer.fill(CGRect(origin: .zero, size: output))
        renderer.cgContext.scaleBy(x: factor, y: factor)
        // UIImage.draw applies EXIF orientation, unlike a raw CGImage crop.
        image.draw(in: imageFrame)
      }
    }
  }
#endif
