#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature

  @MainActor
  struct ListSnapshotFixtures {
    /// Seed EVERY list before attaching any @Query to a window. Saving another store
    /// while a detached TabView query is alive can crash SwiftData. Keep these alive
    /// for the process lifetime, regardless of which test suite runs first.
    static let shared = Result { try ListSnapshotFixtures() }

    let moments: [MomentListPreviewScenario: MomentListPreviewFixture]
    let tags: [AllTagsPreviewScenario: AllTagsPreviewFixture]
    let tagDetails: [TagDetailPreviewScenario: TagDetailPreviewFixture]

    private init() throws {
      moments = try Dictionary(uniqueKeysWithValues: MomentListPreviewScenario.allCases.map {
        try ($0, MomentListPreviewFixture(scenario: $0))
      })
      tags = try Dictionary(uniqueKeysWithValues: AllTagsPreviewScenario.allCases.map {
        try ($0, AllTagsPreviewFixture(scenario: $0))
      })
      tagDetails = try Dictionary(uniqueKeysWithValues: TagDetailPreviewScenario.allCases.map {
        try ($0, TagDetailPreviewFixture(scenario: $0))
      })
    }
  }
#endif
