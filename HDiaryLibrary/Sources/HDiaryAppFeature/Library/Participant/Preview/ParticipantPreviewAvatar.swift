#if DEBUG && os(iOS)
  import SFSafeSymbols
  import UIKit

  /// Identical offline image data for list and detail previews.
  @MainActor
  enum ParticipantPreviewAvatar {
    static func symbol(_ symbol: SFSymbol) -> Data? {
      UIImage(systemSymbol: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 80))
        .withTintColor(.black, renderingMode: .alwaysOriginal)
        .pngData()
    }

    static func colorImage() -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      return UIGraphicsImageRenderer(size: CGSize(width: 120, height: 90), format: format).pngData { _ in
        UIColor(red: 0.1, green: 0.65, blue: 0.7, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 120, height: 90))
        UIColor(red: 1, green: 0.8, blue: 0.1, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: 74, y: 10, width: 28, height: 28)).fill()
        UIColor(red: 1, green: 0.2, blue: 0.4, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(x: 0, y: 50, width: 100, height: 70)).fill()
      }
    }

    static func transparentImage() -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      format.opaque = false
      return UIGraphicsImageRenderer(size: CGSize(width: 76, height: 60), format: format).pngData { _ in }
    }
  }
#endif
