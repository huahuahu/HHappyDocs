#if os(iOS)

import SwiftUI

enum LibraryEntryLayoutPolicy {
  static func forcesSingleColumn(for dynamicTypeSize: DynamicTypeSize) -> Bool {
    dynamicTypeSize.isAccessibilitySize
  }
}

#endif
