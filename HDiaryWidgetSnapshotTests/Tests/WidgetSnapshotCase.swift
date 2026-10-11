#if DEBUG
  @testable import HDiaryWidgetFeature
  import SwiftUI
  import WidgetKit

  struct WidgetSnapshotCase {
    enum Scenario: String {
      case populated, photo, longContent, single, empty, allParticipants, accessibility1

      @MainActor var entry: MomentEntry {
        switch self {
        case .populated: MomentWidgetPreviewFixtures.populated
        case .photo: MomentWidgetPreviewFixtures.photo
        case .longContent, .accessibility1: MomentWidgetPreviewFixtures.longContent
        case .single: MomentWidgetPreviewFixtures.single
        case .empty: MomentWidgetPreviewFixtures.empty
        case .allParticipants: MomentWidgetPreviewFixtures.allParticipants
        }
      }
    }

    enum Appearance: String, CaseIterable {
      case fullColorLight, fullColorDark, accentedLight, accentedDark

      var renderingMode: WidgetRenderingMode {
        switch self {
        case .fullColorLight, .fullColorDark: .fullColor
        case .accentedLight, .accentedDark: .accented
        }
      }

      var colorScheme: ColorScheme {
        switch self {
        case .fullColorLight, .accentedLight: .light
        case .fullColorDark, .accentedDark: .dark
        }
      }
    }

    let scenario: Scenario
    let appearance: Appearance

    var name: String {
      "\(scenario.rawValue)-\(appearance.rawValue)"
    }

    /// Accented snapshots exercise our asset selection, not WidgetKit's final tint/glass composition.
    static let all: [Self] = Appearance.allCases.flatMap { appearance in
      [Self(scenario: .populated, appearance: appearance), Self(scenario: .photo, appearance: appearance)]
    } + [Scenario.longContent, .single, .empty, .allParticipants, .accessibility1].map {
      Self(scenario: $0, appearance: .fullColorLight)
    }
  }
#endif
