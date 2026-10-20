#if os(iOS)
  @testable import HUIComponent
  import Testing
  import UIKit

  @MainActor
  struct HImageCropCanvasTests {
    @Test(arguments: [CGSize(width: 402, height: 874), CGSize(width: 874, height: 402), CGSize(width: 300, height: 260)])
    func fullCanvasUsesTheCircleAsItsContentBoundary(size: CGSize) throws {
      let canvas = makeCanvas(size: size)
      let scroll = canvas.scrollView
      let image = try #require(canvas.viewForZooming(in: scroll))
      let frame = image.convert(image.bounds, to: canvas)
      #expect(scroll.frame == canvas.bounds)
      #expect(frame.width > canvas.cropRect.width)
      #expect(abs(frame.minY - canvas.cropRect.minY) < 0.01)
      #expect(abs(scroll.contentSize.height + scroll.contentInset.top + scroll.contentInset.bottom - size.height) < 0.01)
    }

    @Test(arguments: [false, true])
    func nativePanToEitherEdgeExportsTheVisibleColor(rightEdge: Bool) throws {
      let canvas = makeCanvas()
      let scroll = canvas.scrollView
      scroll.contentOffset.x = rightEdge
        ? scroll.contentSize.width - scroll.bounds.width + scroll.contentInset.right
        : -scroll.contentInset.left
      let result = try canvas.render()
      #expect(result.cgImage?.width == 512)
      #expect(result.cgImage?.height == 512)
      let color = try pixel(result, x: 256, y: 256)
      #expect(rightEdge ? color[2] > 240 && color[0] < 10 : color[0] > 240 && color[2] < 10)
    }

    @Test(arguments: [CGFloat(-10000), 10000])
    func confirmingDuringPanOvershootSettlesBeforeExport(offset: CGFloat) throws {
      let canvas = makeCanvas()
      canvas.scrollView.contentOffset = CGPoint(x: offset, y: offset)
      let result = try canvas.render()
      let scroll = canvas.scrollView
      let image = try #require(canvas.viewForZooming(in: scroll))
      let visible = image.convert(image.bounds, to: canvas)
      #expect(visible.insetBy(dx: -0.01, dy: -0.01).contains(canvas.cropRect))
      for point in [CGPoint(x: 1, y: 1), CGPoint(x: 510, y: 510)] {
        let color = try pixel(result, x: Int(point.x), y: Int(point.y))
        #expect(color[1] < 10, "A bounced edge must not export a white gap")
      }
    }

    @Test
    func rotatingRetainsTheSelectedPhotoRegion() throws {
      let canvas = makeCanvas()
      canvas.zoom(by: 2)
      canvas.move(x: 0.1, y: 0.1)
      let before = try canvas.render()
      canvas.frame.size = CGSize(width: 874, height: 280)
      canvas.setNeedsLayout()
      canvas.layoutIfNeeded()
      let after = try canvas.render()
      for x in stride(from: 16, to: 512, by: 32) {
        #expect(try pixel(before, x: x, y: 256) == pixel(after, x: x, y: 256))
      }
      #expect(abs(try #require(canvas.cropGeometry).scale - 2) < 0.001)
    }

    @Test
    func accessibleZoomPreservesTheSelectedCenterAndResetRestoresIt() throws {
      let canvas = makeCanvas()
      canvas.zoom(by: 2)
      canvas.move(x: 0.1, y: 0)
      let before = try #require(canvas.cropGeometry)
      canvas.accessibilityIncrement()
      let after = try #require(canvas.cropGeometry)
      let centerBefore = (before.viewport.width / 2 - before.imageFrame.minX) / before.imageFrame.width
      let centerAfter = (after.viewport.width / 2 - after.imageFrame.minX) / after.imageFrame.width
      #expect(abs(centerBefore - centerAfter) < 0.001)
      #expect(after.scale > before.scale)
      canvas.reset()
      let reset = try #require(canvas.cropGeometry)
      #expect(abs(reset.scale - 1) < 0.001)
      #expect(abs(reset.offset.width) < 0.01 && abs(reset.offset.height) < 0.01)
    }

    private func makeCanvas(size: CGSize = CGSize(width: 402, height: 874)) -> HImageCropCanvas {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 200), format: format).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
        UIColor.blue.setFill()
        context.fill(CGRect(x: 300, y: 0, width: 300, height: 200))
      }
      let canvas = HImageCropCanvas(image: image, maximumCropSize: CGSize(width: 320, height: 320))
      canvas.frame = CGRect(origin: .zero, size: size)
      canvas.layoutIfNeeded()
      return canvas
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
