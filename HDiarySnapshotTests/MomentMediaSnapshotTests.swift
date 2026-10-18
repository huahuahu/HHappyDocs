#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import Testing

  @Suite(.serialized)
  @MainActor
  struct MomentMediaSnapshotTests {
    @Test("详情图片比例", arguments: MomentMediaPreviewScenario.allCases)
    func media(_ scenario: MomentMediaPreviewScenario) throws {
      try assertSnapshot(
        of: MomentDetailPreview(fixture: MomentMediaPreviewFixture.make(scenario)),
        as: ListSnapshotConfiguration.image(),
        named: ListSnapshotConfiguration.name(scenario.rawValue),
        record: ListSnapshotConfiguration.record,
        testName: "moment-media"
      )
    }
  }
#endif
