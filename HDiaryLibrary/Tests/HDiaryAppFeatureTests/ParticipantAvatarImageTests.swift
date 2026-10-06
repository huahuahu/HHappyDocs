#if os(iOS)
  @testable import HDiaryAppFeature
  import Testing
  import UIKit

  @MainActor
  struct ParticipantAvatarImageTests {
    @Test(arguments: [nil, Data(), Data("invalid image".utf8)] as [Data?])
    func missingOrInvalidImageUsesPlaceholder(data: Data?) async {
      let image = await ParticipantAvatarImage.decode(data)
      #expect(image == nil)
    }

    @Test(arguments: [nil, 2] as [Int?])
    func transparentImageUsesPlaceholderEvenWithAValidHeader(maxPixelSize: Int?) async throws {
      let data = makeImageData { _ in }
      // This is the case UIImage(data:) alone fails to distinguish from a visible avatar.
      try #require(UIImage(data: data) != nil)

      let image = await ParticipantAvatarImage.decode(data, maxPixelSize: maxPixelSize)

      #expect(image == nil)
    }

    @Test
    func visibleArtworkOnTransparentBackgroundIsPreserved() async throws {
      let data = makeImageData { _ in
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 2, y: 2, width: 1, height: 1))
      }

      let image = await ParticipantAvatarImage.decode(data)

      try #require(image != nil)
      #expect(image?.size == CGSize(width: 4, height: 4))
    }

    @Test
    func opaqueImageKeepsItsOriginalColor() async throws {
      let data = makeImageData(opaque: true) { _ in
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 4, height: 4))
      }
      let image = try #require(await ParticipantAvatarImage.decode(data))
      let raster = try #require(image.cgImage)
      let context = try #require(CGContext(
        data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
      ))
      context.draw(raster, in: CGRect(x: 0, y: 0, width: 1, height: 1))
      let pixel = try #require(context.data).assumingMemoryBound(to: UInt8.self)

      #expect(pixel[0] == 255)
      #expect(pixel[1] == 0)
      #expect(pixel[2] == 0)
      #expect(pixel[3] == 255)
    }

    @Test
    func thumbnailIsBoundedButPreviewKeepsOriginalImage() async throws {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let size = CGSize(width: 400, height: 200)
      let data = UIGraphicsImageRenderer(size: size, format: format).pngData { _ in
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
      }

      let thumbnail = try #require(await ParticipantAvatarImage.decode(data, maxPixelSize: 80))
      #expect(thumbnail.cgImage?.width == 80)
      #expect(thumbnail.cgImage?.height == 40)
      let preview = try #require(ParticipantAvatarImage.previewItem(for: data))
      #expect(preview.data == data)
      #expect(preview.previewType == .pngImage)
      #expect(UIImage(data: preview.data)?.size == size)
    }

    private func makeImageData(
      opaque: Bool = false,
      actions: (UIGraphicsImageRendererContext) -> Void
    ) -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = opaque
      return UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).pngData(actions: actions)
    }
  }
#endif
