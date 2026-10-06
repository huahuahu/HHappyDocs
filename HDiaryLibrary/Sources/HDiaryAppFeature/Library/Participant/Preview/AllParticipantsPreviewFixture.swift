#if DEBUG && os(iOS)
  import Foundation
  import HDiaryModel
  import HDiarySearch
  import SwiftData

  /// Saved, isolated data for the actual participants page. Never connects to the user's store.
  @MainActor
  struct AllParticipantsPreviewFixture {
    let scenario: AllParticipantsPreviewScenario
    let container: ModelContainer
    let searchViewModel: SearchViewModel
    let participants: [Participant]

    init(scenario: AllParticipantsPreviewScenario) throws {
      self.scenario = scenario
      container = try ModelContainer(
        for: Moment.self, Tag.self, Participant.self, MediaItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      )
      searchViewModel = SearchViewModel(modelContainer: container)
      let context = container.mainContext
      context.autosaveEnabled = false
      participants = Self.participants(for: scenario)
      for participant in participants {
        context.insert(participant)
      }
      try context.save()
    }

    static func make(_ scenario: AllParticipantsPreviewScenario) -> Self {
      do {
        return try Self(scenario: scenario)
      }
      catch {
        fatalError("Could not create participants preview: \(error)")
      }
    }

    func participant(named name: String) -> Participant {
      do {
        let participants = try container.mainContext.fetch(FetchDescriptor<Participant>())
        guard let participant = participants.first(where: { $0.nickName == name }) else {
          fatalError("Missing participant preview fixture: \(name)")
        }
        return participant
      }
      catch {
        fatalError("Could not read participant preview fixture: \(error)")
      }
    }

    private static func participants(for scenario: AllParticipantsPreviewScenario) -> [Participant] {
      switch scenario {
      case .empty:
        []
      case .populated, .dark:
        [
          person("宝宝"), person("菲菲", avatar: ParticipantPreviewAvatar.symbol(.heartFill)),
          person("俊俊"), person("婷婷"), person("小涵"),
          person("小雨", avatar: ParticipantPreviewAvatar.symbol(.leafFill)),
          person("心心", avatar: ParticipantPreviewAvatar.symbol(.paperplaneFill)),
          person("阳光"), person("宇宝"), person("宇哥"),
        ]
      case .accessibility:
        [
          person("一起记录生活的家人"),
          person("Alexandra Chen", avatar: ParticipantPreviewAvatar.symbol(.heartFill)),
          person("宝宝"), person("小雨 🌿"),
        ]
      case .avatarVariants:
        [
          person("彩色头像", avatar: ParticipantPreviewAvatar.colorImage()),
          person("损坏头像", avatar: Data("invalid image".utf8)),
          person("宝宝", avatar: ParticipantPreviewAvatar.transparentImage()),
          person("默认头像"), person("🌻 小花"),
          Participant.create(name: "真实姓名", nickName: " "),
          Participant.create(name: "", nickName: ""),
        ]
      case .singleParticipant:
        [person("Alexandra")]
      }
    }

    private static func person(_ name: String, avatar: Data? = nil) -> Participant {
      Participant.create(name: name, nickName: name, avatar: avatar)
    }
  }
#endif
