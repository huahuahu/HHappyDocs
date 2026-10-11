#if DEBUG
  @testable import HDiaryWidgetFeature
  import HDiaryWidgetIntents
  import SwiftUI
  import WidgetKit

  // Keep widget previews in the extension so Xcode can find a WidgetKit host.
  #Preview("Entry · Medium", as: .systemMedium) {
    MomentWidget()
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
    MomentWidgetPreviewFixtures.single
    MomentWidgetPreviewFixtures.empty
    MomentWidgetPreviewFixtures.allParticipants
    MomentWidgetPreviewFixtures.photo
  }

  #Preview("Entry · Large", as: .systemLarge) {
    MomentWidget()
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
    MomentWidgetPreviewFixtures.single
    MomentWidgetPreviewFixtures.empty
    MomentWidgetPreviewFixtures.allParticipants
    MomentWidgetPreviewFixtures.photo
  }

  #Preview("Header", as: .systemMedium) {
    MomentWidgetComponentPreview(.header)
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
    MomentWidgetPreviewFixtures.allParticipants
  }

  #Preview("Content · Medium", as: .systemMedium) {
    MomentWidgetComponentPreview(.content(.systemMedium))
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.empty
  }

  #Preview("Content · Large", as: .systemLarge) {
    MomentWidgetComponentPreview(.content(.systemLarge))
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
  }

  #Preview("Moments · Medium", as: .systemMedium) {
    MomentWidgetComponentPreview(.moments(.systemMedium))
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
    MomentWidgetPreviewFixtures.single
  }

  #Preview("Moments · Large", as: .systemLarge) {
    MomentWidgetComponentPreview(.moments(.systemLarge))
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
    MomentWidgetPreviewFixtures.single
  }

  #Preview("Row · Medium", as: .systemMedium) {
    MomentWidgetComponentPreview(.row(.systemMedium))
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
  }

  #Preview("Row · Large", as: .systemLarge) {
    MomentWidgetComponentPreview(.row(.systemLarge))
  } timeline: {
    MomentWidgetPreviewFixtures.populated
    MomentWidgetPreviewFixtures.longContent
  }

  #Preview("Empty · Medium", as: .systemMedium) {
    MomentWidgetComponentPreview(.empty)
  } timeline: {
    MomentWidgetPreviewFixtures.empty
  }

  #Preview("Empty · Large", as: .systemLarge) {
    MomentWidgetComponentPreview(.empty)
  } timeline: {
    MomentWidgetPreviewFixtures.empty
  }
#endif
