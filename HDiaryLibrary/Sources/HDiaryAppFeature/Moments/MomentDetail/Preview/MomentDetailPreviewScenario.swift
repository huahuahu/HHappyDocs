#if DEBUG && os(iOS)
  import SwiftUI

  enum MomentDetailPreviewScenario: String, CaseIterable {
    case populated
    case minimal
    case longContent = "long-content"
    case dark
    case accessibility
    case compactAccessibility = "compact-accessibility"

    var dynamicTypeSize: DynamicTypeSize {
      switch self {
      case .accessibility:
        .accessibility3
      case .compactAccessibility:
        .accessibility2
      default:
        .large
      }
    }
  }
#endif
