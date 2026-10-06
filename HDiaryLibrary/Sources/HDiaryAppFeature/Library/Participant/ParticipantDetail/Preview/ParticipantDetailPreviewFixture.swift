#if DEBUG && os(iOS)
  import Foundation
  import HDiaryModel
  import HDiarySearch
  import SwiftData

  @MainActor
  struct ParticipantDetailPreviewFixture {
    let scenario: ParticipantDetailPreviewScenario
    let container: ModelContainer
    let searchViewModel: SearchViewModel
    let participant: Participant

    init(scenario: ParticipantDetailPreviewScenario) throws {
      self.scenario = scenario
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      let context = container.mainContext
      context.autosaveEnabled = false
      searchViewModel = SearchViewModel(modelContainer: container)

      switch scenario {
      case .empty:
        participant = Participant.create(name: "陈小雨", nickName: "小雨")
      case .transparentAvatar:
        participant = Participant.create(
          name: "小宝", nickName: "宝宝", note: "一起记录成长中的小小惊喜。",
          avatar: ParticipantPreviewAvatar.transparentImage()
        )
      case .populated, .dark, .accessibility:
        participant = Participant.create(
          name: "陈小雨", nickName: "小雨",
          note: "喜欢散步、拍照，也喜欢一起发现生活里的小惊喜。\n周末有空就去公园走走 🌿。",
          avatar: ParticipantPreviewAvatar.colorImage()
        )
      }
      context.insert(participant)

      let titles = ["一起在公园看日落", "周末做了一顿好吃的早餐", "发现街角的新书店 📚"]
      if scenario != .empty {
        // Insert oldest first; the actual detail page must render newest first.
        for (index, title) in titles.enumerated().reversed() {
          let moment = Moment.create(timestamp: Date(timeIntervalSince1970: 1_791_000_000 - Double(index * 86_400)))
          context.insert(moment)
          moment.updateTitle(title)
          moment.updateParticipants([participant])
        }
      }

      let otherParticipant = Participant.create(name: "其他参与者", nickName: "其他参与者")
      context.insert(otherParticipant)
      let unrelatedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 1_791_000_000))
      context.insert(unrelatedMoment)
      unrelatedMoment.updateTitle("不属于当前参与者的乐事")
      unrelatedMoment.updateParticipants([otherParticipant])
      try context.save()
    }

    static func make(_ scenario: ParticipantDetailPreviewScenario) -> Self {
      do {
        return try Self(scenario: scenario)
      }
      catch {
        fatalError("Could not create participant detail preview: \(error)")
      }
    }
  }
#endif
