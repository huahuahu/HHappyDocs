#if DEBUG && os(iOS)
  import SnapshotTesting
  import SwiftUI

  @MainActor
  enum ListSnapshotConfiguration {
    static var record: SnapshotTestingConfiguration.Record {
      ProcessInfo.processInfo.environment["HDIARY_RECORD_SNAPSHOTS"] == "1" ? .all : .never
    }

    static func image<V: View>(
      style: UIUserInterfaceStyle = .light,
      contentSize: UIContentSizeCategory = .large,
      width: CGFloat = 402
    ) -> Snapshotting<V, UIImage> {
      let traits = UITraitCollection {
        $0.userInterfaceStyle = style
        $0.displayScale = 3
        $0.preferredContentSizeCategory = contentSize
      }
      let config = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
        size: CGSize(width: width, height: 874), traits: traits
      )
      // System glass shadows vary by 1–2 RGB levels across local and CI renders.
      // Check every pixel; tolerate only the previously measured perceptual noise.
      return .image(
        drawHierarchyInKeyWindow: true, precision: 1, perceptualPrecision: 0.94,
        layout: .device(config: config), traits: traits
      )
    }
  }
#endif
