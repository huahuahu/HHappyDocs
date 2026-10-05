#if DEBUG && os(iOS)
  import Foundation
  import HDiaryModel
  import HDiarySearch
  import SwiftData
  import SwiftUI

  /// Saved, offline data shared by the tag detail previews and image assertions.
  @MainActor
  struct TagDetailPreviewFixture {
    let scenario: TagDetailPreviewScenario
    let container: ModelContainer
    let searchViewModel: SearchViewModel
    let tag: Tag

    static var calendar: Calendar {
      var calendar = Calendar(identifier: .gregorian)
      calendar.locale = Locale(identifier: "zh_CN")
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
      return calendar
    }

    private static let referenceDate = date(month: 10, day: 3)

    init(scenario: TagDetailPreviewScenario) throws {
      self.scenario = scenario
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      let context = container.mainContext
      context.autosaveEnabled = false
      searchViewModel = SearchViewModel(modelContainer: container)

      tag = Tag(text: "城市", comments: "城市探索充满惊喜")
      if scenario == .longContent {
        tag.text = "与朋友一起探索城市街巷里的美好时光"
        tag.comments = "沿着熟悉的街道慢慢散步，发现一家小店、一处建筑，或是一段值得记住的对话。\n把不同语言、不同季节里的城市记忆留在这里 🌇。"
      }
      tag.creationDate = Self.referenceDate
      context.insert(tag)

      func insert(_ title: String, rating: Int, at date: Date, tag: Tag) {
        let moment = Moment.create(timestamp: date)
        context.insert(moment)
        moment.updateTitle(title)
        moment.updateRating(rating)
        moment.updateTags([tag])
        moment.lastVisitDate = Self.referenceDate
      }

      if scenario != .empty {
        let firstTitle = scenario == .longContent || scenario.dynamicTypeSize.isAccessibilitySize
          ? "和朋友一起探索城市里那些藏在街巷深处、值得慢慢品尝的美食与故事"
          : "探索城市美食"
        let entries: [(title: String, rating: Int, date: Date)] = [
          (firstTitle, 2, Self.date(month: 9, day: 29)),
          ("Exploring City Cuisine", 1, Self.date(month: 9, day: 28)),
          ("Hiking in Natural Landscapes", 4, Self.date(month: 9, day: 26)),
          ("Paseo por la Playa", 3, Self.date(month: 8, day: 30)),
          ("Exploring City Cuisine", 5, Self.date(month: 8, day: 27)),
          ("Exploring City Cuisine", 3, Self.date(month: 8, day: 17)),
          ("Exploring City Cuisine", 3, Self.date(month: 8, day: 16)),
          ("音乐和街角的咖啡 ☕️", 4, Self.date(month: 8, day: 12)),
          ("傍晚沿河散步", 2, Self.date(month: 7, day: 20)),
          ("发现一间独立书店", 5, Self.date(month: 7, day: 3)),
        ]
        // Insert oldest first so snapshots also catch loss of the page's date sorting.
        for entry in entries.reversed() {
          insert(entry.title, rating: entry.rating, at: entry.date, tag: tag)
        }
      }

      // The empty state must depend on this tag, even when the store has other moments.
      let otherTag = Tag(text: "其他")
      otherTag.creationDate = Self.referenceDate
      context.insert(otherTag)
      insert("不属于城市的乐事", rating: 5, at: Self.referenceDate, tag: otherTag)
      try context.save()
    }

    private static func date(month: Int, day: Int) -> Date {
      calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
  }
#endif
