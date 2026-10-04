#if DEBUG && os(iOS)

  @testable import HDiaryAppFeature
  import Foundation
  import HDiaryModel
  import SwiftData
  import Testing

  @MainActor
  struct MomentListFixtureTests {
    @Test("截图数据隔离：删除一份数据不会污染另一个场景")
    func isolatesScenarios() throws {
      let first = try MomentListPreviewFixture(scenario: .grouped)
      let second = try MomentListPreviewFixture(scenario: .grouped)
      let empty = try MomentListPreviewFixture(scenario: .empty)
      let visible = FetchDescriptor<Moment>(predicate: #Predicate { !$0.markedAsDelete })
      try first.container.mainContext.delete(model: Moment.self)
      try first.container.mainContext.save()

      #expect(try first.container.mainContext.fetchCount(visible) == 0)
      #expect(try second.container.mainContext.fetchCount(visible) == 7)
      #expect(try empty.container.mainContext.fetchCount(visible) == 0)
      #expect(second.cloudState.shouldSync == false)
    }
  }

#endif
