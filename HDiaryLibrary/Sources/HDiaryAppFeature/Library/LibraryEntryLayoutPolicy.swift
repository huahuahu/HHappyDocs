#if os(iOS)

import SwiftUI

enum LibraryEntryLayoutPolicy {
  static func forcesSingleColumn(for dynamicTypeSize: DynamicTypeSize) -> Bool {
    dynamicTypeSize.isAccessibilitySize
  }

  static func singleColumnContentAxis(
    for dynamicTypeSize: DynamicTypeSize
  ) -> Axis {
    dynamicTypeSize.isAccessibilitySize ? .vertical : .horizontal
  }
}

#endif
