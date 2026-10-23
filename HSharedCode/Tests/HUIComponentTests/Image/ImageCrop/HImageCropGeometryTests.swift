#if os(iOS)
  @testable import HUIComponent
  import Testing
  import UIKit

  @MainActor
  struct HImageCropGeometryTests {
    @Test(arguments: [CGSize(width: 900, height: 300), CGSize(width: 300, height: 900), CGSize(width: 300, height: 300)])
    func extremeOffsetsNeverExposeOutsideTheImage(imageSize: CGSize) {
      let viewport = CGSize(width: 280, height: 280)
      for scale: CGFloat in [0.1, 1, 3, 100] {
        for position: CGFloat in [-10000, 10000] {
          let crop = HImageCropGeometry(imageSize: imageSize, viewport: viewport, scale: scale, offset: CGSize(width: position, height: position))
          #expect(crop.imageFrame.minX <= 0)
          #expect(crop.imageFrame.minY <= 0)
          #expect(crop.imageFrame.maxX >= viewport.width)
          #expect(crop.imageFrame.maxY >= viewport.height)
          #expect((1...5).contains(crop.scale))
        }
      }
    }

    @Test
    func exportUsesTheSelectedRegionAndHasBoundedResolution() throws {
      let image = stripedPhoto()
      let viewport = CGSize(width: 200, height: 200)
      for position: CGFloat in [-1000, 1000] {
        let crop = HImageCropGeometry(imageSize: image.size, viewport: viewport, scale: 1, offset: CGSize(width: position, height: 0))
        let result = try crop.render(image)
        #expect(result.cgImage?.width == 512)
        #expect(result.cgImage?.height == 512)
        #expect(result.imageOrientation == .up)
        let color = try pixel(result, x: 256, y: 256)
        #expect(position > 0 ? color[0] > 240 && color[2] < 10 : color[2] > 240 && color[0] < 10)
      }
    }

    @Test(arguments: [UIImage.Orientation.up, .down, .left, .right, .upMirrored, .downMirrored, .leftMirrored, .rightMirrored])
    func orientationMatchesAnUprightReference(orientation: UIImage.Orientation) throws {
      let raster = try #require(stripedPhoto().cgImage)
      let image = UIImage(cgImage: raster, scale: 1, orientation: orientation)
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let upright = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
        image.draw(in: CGRect(origin: .zero, size: image.size))
      }
      let crop = HImageCropGeometry(imageSize: image.size, viewport: CGSize(width: 240, height: 240), scale: 2, offset: CGSize(width: 50, height: -40))
      let actual = try crop.render(image)
      let expected = try crop.render(upright)
      for point in [CGPoint(x: 40, y: 100), CGPoint(x: 400, y: 100), CGPoint(x: 100, y: 400)] {
        #expect(try pixel(actual, x: Int(point.x), y: Int(point.y)) == pixel(expected, x: Int(point.x), y: Int(point.y)))
      }
    }

    @Test
    func invalidImageFailsInsteadOfProducingAnEmptyAvatar() {
      let crop = HImageCropGeometry(imageSize: .zero, viewport: CGSize(width: 200, height: 200), scale: 1, offset: .zero)
      #expect(throws: CocoaError.self) { try crop.render(UIImage()) }
    }

    private func stripedPhoto() -> UIImage {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 200), format: format).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
        UIColor.blue.setFill()
        context.fill(CGRect(x: 300, y: 0, width: 300, height: 200))
      }
    }

    private func pixel(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
      let raster = try #require(image.cgImage?.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)))
      let context = try #require(CGContext(
        data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ))
      context.draw(raster, in: CGRect(x: 0, y: 0, width: 1, height: 1))
      let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
      return Array(UnsafeBufferPointer(start: bytes, count: 4))
    }
  }
#endif
