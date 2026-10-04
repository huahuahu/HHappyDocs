#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import HDiaryModel
  import SwiftData
  import Testing

  @MainActor
  struct AllTagsFixtureTests {
    @Test("标签数据使用保存后的真实乐事关系")
    func preservesMomentCounts() throws {
      let fixture = try AllTagsPreviewFixture(scenario: .populated)
      let context = ModelContext(fixture.container)
      let tags = try context.fetch(FetchDescriptor<HDiaryModel.Tag>())
      let counts = Dictionary(uniqueKeysWithValues: tags.map { ($0.text, $0.moments?.count ?? 0) })
      #expect(counts == ["旅行": 0, "生活": 1, "自然": 3, "阅读": 12])
      #expect(try context.fetchCount(FetchDescriptor<Moment>()) == 16)
    }

    @Test("删除一份标签数据不影响其他场景")
    func isolatesScenarios() throws {
      let first = try AllTagsPreviewFixture(scenario: .populated)
      let second = try AllTagsPreviewFixture(scenario: .populated)
      let empty = try AllTagsPreviewFixture(scenario: .empty)
      try first.container.mainContext.delete(model: HDiaryModel.Tag.self)
      try first.container.mainContext.save()

      let tags = FetchDescriptor<HDiaryModel.Tag>()
      #expect(try first.container.mainContext.fetchCount(tags) == 0)
      #expect(try second.container.mainContext.fetchCount(tags) == 4)
      #expect(try empty.container.mainContext.fetchCount(tags) == 0)
      #expect(second.container.configurations.allSatisfy { $0.isStoredInMemoryOnly })
      #expect(second.container.configurations.allSatisfy { $0.cloudKitContainerIdentifier == nil })
    }
  }
#endif
