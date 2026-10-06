#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import HDiaryModel
  import UIKit

  @MainActor
  enum ParticipantSnapshotPreparation {
    static func prepareAvatars(_ participants: [Participant]) async throws {
      // Match the largest tested body-scaled avatar at 3x in every scenario, so a
      // previous test cannot change the rendition reused from the shared cache.
      let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge)
      let size = UIFontMetrics(forTextStyle: .body).scaledValue(for: 64, compatibleWith: traits)
      let maxPixelSize = Int((size * 3).rounded(.up))
      for participant in participants {
        if let data = participant.avatar {
          _ = try await ParticipantAvatarImageStore.shared.image(for: data, maxPixelSize: maxPixelSize)
        }
      }
    }
  }
#endif
