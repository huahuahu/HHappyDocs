#if DEBUG && os(iOS)
  import SwiftUI

  enum TagDetailPreviewScenario: String, CaseIterable {
    case populated
    case empty
    case longContent = "long-content"
    case dark
    case accessibility
    case accessibilityMax = "accessibility-max"
    case compactAccessibility = "compact-accessibility"

    var colorScheme: ColorScheme {
      self == .dark ? .dark : .light
    }

    var dynamicTypeSize: DynamicTypeSize {
      switch self {
      case .accessibility, .compactAccessibility:
        .accessibility2
      case .accessibilityMax:
        .accessibility5
      default:
        .large
      }
    }
  }
#endif
