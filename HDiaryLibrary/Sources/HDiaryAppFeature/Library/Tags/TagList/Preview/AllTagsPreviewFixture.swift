#if DEBUG && os(iOS)
  import Foundation
  import HDiaryModel
  import HDiarySearch
  import SwiftData

  /// Each preview or test gets its own saved, offline store, including real inverse relationships.
  @MainActor
  struct AllTagsPreviewFixture {
    let scenario: AllTagsPreviewScenario
    let container: ModelContainer
    let searchViewModel: SearchViewModel

    static var calendar: Calendar {
      var calendar = Calendar(identifier: .gregorian)
      calendar.locale = Locale(identifier: "zh_CN")
      calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
      return calendar
    }

    private static let referenceDate = Date(timeIntervalSince1970: 1_791_000_000)

    init(scenario: AllTagsPreviewScenario) throws {
      self.scenario = scenario
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      let context = container.mainContext
      context.autosaveEnabled = false
      searchViewModel = SearchViewModel(modelContainer: container)

      let entries: [(name: String, momentCount: Int)] = switch scenario {
      case .empty:
        []
      case .populated, .dark:
        [("阅读", 12), ("旅行", 0), ("生活", 1), ("自然", 3)]
      case .longNames:
        [
          ("和家人一起慢慢收集生活中那些平凡却值得认真记住的小确幸", 12),
          ("Little everyday moments worth remembering together", 1),
          ("散步 🌿 · 咖啡 ☕️ · 好心情 ✨", 0),
        ]
      case .accessibility:
        [("和家人一起收集生活里的小确幸", 12), ("散步 🌿", 0)]
      }

      for entry in entries {
        let tag = Tag(text: entry.name)
        tag.creationDate = Self.referenceDate
        context.insert(tag)
        for index in 0 ..< entry.momentCount {
          let moment = Moment.create(timestamp: Self.referenceDate)
          context.insert(moment)
          moment.updateTitle("截图专用乐事 \(index + 1)")
          moment.updateTags([tag])
          moment.lastVisitDate = Self.referenceDate
        }
      }
      try context.save()
    }
  }
#endif
