#if os(iOS)
  /// A stable action target; gesture updates stay in UIKit instead of invalidating SwiftUI.
  final class HImageCropEditor {
    weak var canvas: HImageCropCanvas?
  }
#endif
