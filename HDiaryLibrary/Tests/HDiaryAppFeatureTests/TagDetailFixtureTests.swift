#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import Foundation
  import HDiaryModel
  import SwiftData
  import Testing

  @MainActor
  struct TagDetailFixtureTests {
    @Test("标签详情保存十条固定日期、评分的真实关联乐事")
    func preservesCityMoments() throws {
      let fixture = try TagDetailPreviewFixture(scenario: .populated)
      let context = ModelContext(fixture.container)
      let tags = try context.fetch(FetchDescriptor<HDiaryModel.Tag>())
      let city = try #require(tags.first { $0.text == "城市" })
      let moments = try #require(city.moments).sorted { $0.timestamp > $1.timestamp }
      #expect(city.comments == "城市探索充满惊喜")
      #expect(moments.count == 10)
      #expect(moments.map(\.rating) == [2, 1, 4, 3, 5, 3, 3, 4, 2, 5])
      let first = try #require(moments.first)
      #expect(first.title == "探索城市美食")
      #expect(first.timestamp == TagDetailPreviewFixture.calendar.date(
        from: DateComponents(year: 2026, month: 9, day: 29, hour: 12)
      ))
      #expect(moments.contains { $0.title == "不属于城市的乐事" } == false)
      #expect(try context.fetchCount(FetchDescriptor<Moment>()) == 11)
    }

    @Test("无关联乐事的标签在其他标签有数据时仍为空")
    func emptyTagHasNoRelatedMoments() throws {
      let fixture = try TagDetailPreviewFixture(scenario: .empty)
      let context = ModelContext(fixture.container)
      let city = try #require(context.fetch(FetchDescriptor<HDiaryModel.Tag>()).first { $0.text == "城市" })
      #expect(city.moments?.count == 0)
      #expect(try context.fetchCount(FetchDescriptor<Moment>()) == 1)
    }

    @Test("标签详情的场景使用彼此隔离的离线内存数据库")
    func isolatesScenarios() throws {
      let first = try TagDetailPreviewFixture(scenario: .populated)
      let second = try TagDetailPreviewFixture(scenario: .populated)
      try first.container.mainContext.delete(model: Moment.self)
      try first.container.mainContext.save()

      #expect(try first.container.mainContext.fetchCount(FetchDescriptor<Moment>()) == 0)
      #expect(try second.container.mainContext.fetchCount(FetchDescriptor<Moment>()) == 11)
      #expect(second.tag.moments?.count == 10)
      #expect(second.container.configurations.allSatisfy { $0.isStoredInMemoryOnly })
      #expect(second.container.configurations.allSatisfy { $0.cloudKitContainerIdentifier == nil })
    }
  }
#endif
