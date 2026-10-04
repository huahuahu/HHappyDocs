#if DEBUG && os(iOS)
  import SwiftUI

  enum AllTagsPreviewScenario: String, CaseIterable {
    case empty
    case populated
    case longNames = "long-names"
    case dark
    case accessibility

    var colorScheme: ColorScheme {
      self == .dark ? .dark : .light
    }

    var dynamicTypeSize: DynamicTypeSize {
      self == .accessibility ? .accessibility2 : .large
    }
  }
#endif
