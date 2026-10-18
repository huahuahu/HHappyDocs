#if DEBUG && os(iOS)
  import HDiaryModel
  import ImageIO
  import SwiftUI
  import UIKit
  import UniformTypeIdentifiers

  enum MomentMediaPreviewScenario: String, CaseIterable {
    case landscape, portrait, square, tall, panorama, mixed

    var size: CGSize {
      switch self {
      case .landscape, .mixed: CGSize(width: 900, height: 600)
      case .portrait: CGSize(width: 600, height: 900)
      case .square: CGSize(width: 600, height: 600)
      case .tall: CGSize(width: 240, height: 1800)
      case .panorama: CGSize(width: 1800, height: 240)
      }
    }
  }

  /// The same offline fixture is used by Canvas, screenshots and simulator interaction checks.
  @MainActor
  enum MomentMediaPreviewFixture {
    static let active: MomentDetailPreviewFixture? = {
      guard let value = ProcessInfo.processInfo.environment["HDIARY_MEDIA_PREVIEW"],
            let scenario = MomentMediaPreviewScenario(rawValue: value) else { return nil }
      return make(scenario)
    }()

    static func make(_ scenario: MomentMediaPreviewScenario) -> MomentDetailPreviewFixture {
      let fixture = MomentDetailPreviewFixture.make(.minimal)
      fixture.moment.updateTitle("把不同形状的风景留下来")
      fixture.moment.updateContent("湖边散步的一天。轻点照片查看原图，左右滑动查看下一张。")
      let scenarios: [MomentMediaPreviewScenario] = scenario == .mixed
        ? [.landscape, .portrait, .square, .tall, .panorama, .mixed] : [scenario]
      for item in scenarios {
        let image = image(item)
        guard let thumbnail = image.pngData() else {
          preconditionFailure("Cannot encode preview image")
        }
        let animated = item == .mixed
        fixture.container.mainContext.insert(MediaItem(
          data: animated ? gif(image: image) : thumbnail,
          moment: fixture.moment,
          mediaType: animated ? .gif : .image,
          pathExtension: animated ? "GIF" : "png",
          thumbnailData150px: thumbnail, thumbnailData500px: thumbnail, thumbnailData1000px: thumbnail
        ))
      }
      do {
        try fixture.container.mainContext.save()
      }
      catch {
        preconditionFailure("Cannot save media preview: \(error)")
      }
      return fixture
    }

    private static func image(_ scenario: MomentMediaPreviewScenario) -> UIImage {
      let size = scenario.size
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = true
      return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
        let context = renderer.cgContext
        UIColor(red: 0.91, green: 0.95, blue: 0.94, alpha: 1).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        UIColor(red: 0.22, green: 0.52, blue: 0.50, alpha: 1).setStroke()
        context.setLineWidth(12)
        context.stroke(CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 6))
        // A circle and four corner marks make stretching and cropping visible.
        let diameter = min(size.width, size.height) * 0.45
        UIColor.systemOrange.setFill()
        context.fillEllipse(in: CGRect(
          x: (size.width - diameter) / 2,
          y: (size.height - diameter) / 2,
          width: diameter,
          height: diameter
        ))
        for point in [
          CGPoint(x: 24, y: 24),
          CGPoint(x: size.width - 64, y: 24),
          CGPoint(x: 24, y: size.height - 64),
          CGPoint(x: size.width - 64, y: size.height - 64),
        ] {
          UIColor.systemTeal.setFill()
          context.fill(CGRect(origin: point, size: CGSize(width: 40, height: 40)))
        }
        let label = "\(scenario.rawValue.uppercased())  \(Int(size.width)) × \(Int(size.height))"
        (label as NSString).draw(at: CGPoint(x: 26, y: 84), withAttributes: [
          .font: UIFont.systemFont(ofSize: min(size.width, size.height) / 18, weight: .semibold),
          .foregroundColor: UIColor.black,
        ])
      }
    }

    private static func gif(image: UIImage) -> Data {
      let data = NSMutableData()
      guard let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 2, nil),
            let firstFrame = image.cgImage,
            let secondFrame = self.image(.square).cgImage else { preconditionFailure("Cannot create GIF fixture") }
      CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
      let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.5]] as CFDictionary
      CGImageDestinationAddImage(destination, firstFrame, properties)
      CGImageDestinationAddImage(destination, secondFrame, properties)
      guard CGImageDestinationFinalize(destination) else { preconditionFailure("Cannot encode GIF fixture") }
      return data as Data
    }
  }

  #Preview("图片比例 · 混合分页") {
    MomentDetailPreview(fixture: MomentMediaPreviewFixture.make(.mixed))
  }

  #Preview("图片比例 · 长图") {
    MomentDetailPreview(fixture: MomentMediaPreviewFixture.make(.tall))
  }

  #Preview("图片比例 · 全景图") {
    MomentDetailPreview(fixture: MomentMediaPreviewFixture.make(.panorama))
  }
#endif
