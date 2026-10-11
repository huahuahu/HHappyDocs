#if os(iOS)

  import CoreImage
  import Foundation
  import HDiaryModel
  import HDiaryWidgetData
  import HDiaryWidgetIntents
  @testable import HDiaryWidgetSnapshotSync
  import ImageIO
  import SwiftData
  import Testing
  import UniformTypeIdentifiers

  struct WidgetAvatarThumbnailerTests {
    @Test("10-bit HEIC 缩小后保留格式、位深、Display P3 和可见内容")
    func tenBitHEICPreservesFormatDepthAndColorSpace() async throws {
      let data = try tenBitAvatarData()
      let thumbnail = await WidgetAvatarThumbnailer.thumbnailData(from: data, maxPixelSize: 64)
      let encoded = try #require(thumbnail)
      let source = try #require(CGImageSourceCreateWithData(encoded as CFData, nil))
      #expect(CGImageSourceGetType(source) == UTType.heic.identifier as CFString)
      let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
      #expect(properties[kCGImagePropertyDepth] as? Int == 10)
      let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))

      #expect(image.width == 64)
      #expect(image.height == 32)
      #expect(image.bitsPerComponent == 10)
      #expect(image.colorSpace?.name == CGColorSpace.displayP3)
      expectRedAndGreenContent(in: image)
      try expectDisplayP3Primaries(in: image)
    }

    @Test("普通头像缩小后保留格式、Display P3 和 PNG 透明度", arguments: [UTType.jpeg, .png, .heic])
    func commonFormatsPreserveImageProperties(_ type: UTType) async throws {
      let data = try makeAvatarData(type: type)
      let thumbnail = await WidgetAvatarThumbnailer.thumbnailData(from: data, maxPixelSize: 64)
      let encoded = try #require(thumbnail)
      let source = try #require(CGImageSourceCreateWithData(encoded as CFData, nil))
      #expect(CGImageSourceGetType(source) == type.identifier as CFString)
      let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
      #expect(image.width == 64)
      #expect(image.height == 32)
      #expect(image.bitsPerComponent == 8)
      #expect(image.colorSpace?.name == CGColorSpace.displayP3)
      expectRedAndGreenContent(in: image)
      try expectDisplayP3Primaries(in: image)
      if type == .png {
        let pixel = try pixelComponents(in: image, x: 4)
        #expect(pixel[3] == 0)
      }
    }

    @Test("JPEG 缩略图应用原图方向，保持竖图比例")
    func jpegOrientationIsApplied() async throws {
      let data = try makeAvatarData(type: .jpeg, orientation: 6)
      let thumbnail = await WidgetAvatarThumbnailer.thumbnailData(from: data, maxPixelSize: 64)
      let encoded = try #require(thumbnail)
      let source = try #require(CGImageSourceCreateWithData(encoded as CFData, nil))
      let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
      #expect(CGImageSourceGetType(source) == UTType.jpeg.identifier as CFString)
      #expect(image.width == 32)
      #expect(image.height == 64)
      let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
      #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test("10-bit 头像经过快照存储和 Widget 读取后不会回退为默认人像")
    @MainActor
    func tenBitAvatarSurvivesSnapshotAndWidgetRead() async throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, Participant.self])
      let primaryContainer = try ModelContainer(
        for: schema,
        configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
      )
      let participant = Participant.create(name: "Avatar", nickName: "Avatar", avatar: try tenBitAvatarData())
      primaryContainer.mainContext.insert(participant)
      try primaryContainer.mainContext.save()

      let snapshot = try await MainStoreWidgetSnapshotBuilder(container: primaryContainer).build()
      let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
      defer { try? FileManager.default.removeItem(at: directory) }
      let url = directory.appending(path: "widget-snapshot.sqlite")
      let writer = WidgetSnapshotStore(modelContainer: try WidgetSnapshotContainer.makeWriterContainer(at: url))
      try await writer.replace(with: snapshot)

      let reader = MomentWidgetDataSource(modelContainer: try WidgetSnapshotContainer.makeReaderContainer(at: url))
      let value = try #require(reader.fetchParticipants().first { $0.uuid == participant.uuid })
      let encoded = try #require(value.avatarThumbnailData)
      let source = try #require(CGImageSourceCreateWithData(encoded as CFData, nil))
      #expect(CGImageSourceGetType(source) == UTType.heic.identifier as CFString)
      let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
      #expect(properties[kCGImagePropertyDepth] as? Int == 10)
      let entity = ParticipantEntity(from: value)
      #expect(entity.avatar.isSymbolImage == false)
      let image = try #require(entity.avatar.cgImage)
      expectRedAndGreenContent(in: image)
      try expectDisplayP3Primaries(in: image)
    }

    private func tenBitAvatarData() throws -> Data {
      // Saturated Display P3 CGColors, wrapped in CIColor(cgColor:), fill the left/right halves.
      // CIContext.heif10Representation exports this 256 × 128 synthetic image at quality 1.0.
      let url = try #require(Bundle.module.url(forResource: "avatar-10bit", withExtension: "heic"))
      let data = try Data(contentsOf: url)
      let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
      let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
      try #require(properties[kCGImagePropertyDepth] as? Int == 10)
      let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
      try #require(image.colorSpace?.name == CGColorSpace.displayP3)
      try expectDisplayP3Primaries(in: image)
      return data
    }

    private func makeAvatarData(type: UTType, orientation: Int = 1) throws -> Data {
      let colorSpace = try #require(CGColorSpace(name: CGColorSpace.displayP3))
      let context = try #require(CGContext(
        data: nil, width: 256, height: 128, bitsPerComponent: 8, bytesPerRow: 256 * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
      ))
      context.setFillColor(try #require(CGColor(colorSpace: colorSpace, components: [1, 0, 0, 1])))
      context.fill(CGRect(x: 0, y: 0, width: 128, height: 128))
      context.setFillColor(try #require(CGColor(colorSpace: colorSpace, components: [0, 1, 0, 1])))
      context.fill(CGRect(x: 128, y: 0, width: 128, height: 128))
      if type == .png {
        context.clear(CGRect(x: 0, y: 0, width: 32, height: 128))
      }
      let output = NSMutableData()
      let destination = try #require(CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil))
      CGImageDestinationAddImage(destination, try #require(context.makeImage()), [
        kCGImageDestinationLossyCompressionQuality: 1.0,
        kCGImagePropertyOrientation: orientation,
      ] as CFDictionary)
      try #require(CGImageDestinationFinalize(destination))
      return output as Data
    }

    private func expectDisplayP3Primaries(in image: CGImage, sourceLocation: SourceLocation = #_sourceLocation) throws {
      // These P3 primaries are outside sRGB. Checking pixels in P3 catches gamut clipping
      // even if an encoder were to attach a P3 profile after converting to sRGB.
      let left = try pixelComponents(in: image, x: image.width / 4)
      let right = try pixelComponents(in: image, x: image.width * 3 / 4)
      #expect(left[0] > 0.95 && left[1] < 0.05 && left[2] < 0.05, sourceLocation: sourceLocation)
      #expect(right[0] < 0.05 && right[1] > 0.95 && right[2] < 0.05, sourceLocation: sourceLocation)
      #expect(left[3] == 1 && right[3] == 1, sourceLocation: sourceLocation)
    }

    private func pixelComponents(in image: CGImage, x: Int) throws -> [Float] {
      var pixel = [Float](repeating: 0, count: 4)
      let colorSpace = try #require(CGColorSpace(name: CGColorSpace.displayP3))
      CIContext().render(CIImage(cgImage: image), toBitmap: &pixel, rowBytes: 4 * MemoryLayout<Float>.size,
                         bounds: CGRect(x: x, y: image.height / 2, width: 1, height: 1),
                         format: .RGBAf, colorSpace: colorSpace)
      return pixel
    }

    private func expectRedAndGreenContent(in image: CGImage, sourceLocation: SourceLocation = #_sourceLocation) {
      let context = CIContext()
      let input = CIImage(cgImage: image)
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      var left = [UInt8](repeating: 0, count: 4)
      var right = [UInt8](repeating: 0, count: 4)
      context.render(input, toBitmap: &left, rowBytes: 4,
                     bounds: CGRect(x: image.width / 4, y: image.height / 2, width: 1, height: 1),
                     format: .RGBA8, colorSpace: colorSpace)
      context.render(input, toBitmap: &right, rowBytes: 4,
                     bounds: CGRect(x: image.width * 3 / 4, y: image.height / 2, width: 1, height: 1),
                     format: .RGBA8, colorSpace: colorSpace)
      #expect(left[0] > 200 && left[1] < 50 && left[2] < 50, sourceLocation: sourceLocation)
      #expect(right[0] < 50 && right[1] > 200 && right[2] < 50, sourceLocation: sourceLocation)
      #expect(left[3] == 255 && right[3] == 255, sourceLocation: sourceLocation)
    }
  }

#endif
