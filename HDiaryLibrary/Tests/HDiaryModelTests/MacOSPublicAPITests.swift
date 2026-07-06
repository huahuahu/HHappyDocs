#if os(macOS)

  import Foundation
  import SwiftData
  import Testing
  import HDiaryModel

  struct MacOSPublicAPITests {
    @Test
    @available(macOS 14.0, *)
    func coreModelAPIsAreAvailableOnMacOS() {
      let moment = Moment.create(timestamp: Date(timeIntervalSince1970: 1))
      moment.updateTitle("macOS")
      moment.updateContent("public API")

      let participant = Participant.create(name: "name", nickName: "nick")
      let tag = Tag(text: "tag")

      moment.updateParticipants([participant])
      moment.updateTags([tag])

      #expect(moment.title == "macOS")
      #expect(moment.content == "public API")
      #expect(participant.nickName == "nick")
      #expect(tag.title == "tag")
    }

    @Test
    @available(macOS 14.0, *)
    func exportAPIIsAvailableOnMacOS() throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      let container = try ModelContainer(for: schema, configurations: [configuration])

      let rawDataCollection = RawDataCollection(modelContext: ModelContext(container))
      #expect(String(describing: type(of: rawDataCollection)) == "RawDataCollection")
    }
  }

#endif
