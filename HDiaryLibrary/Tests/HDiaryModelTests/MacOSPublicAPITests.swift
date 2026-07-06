#if os(macOS)

  import SwiftData
  import XCTest
  @testable import HDiaryModel

  @available(macOS 14.0, *)
  final class MacOSPublicAPITests: XCTestCase {
    func testCoreModelAPIsAreAvailableOnMacOS() {
      let moment = Moment.create(timestamp: Date(timeIntervalSince1970: 1))
      moment.updateTitle("macOS")
      moment.updateContent("public API")

      let participant = Participant.create(name: "name", nickName: "nick")
      let tag = Tag(text: "tag")

      moment.updateParticipants([participant])
      moment.updateTags([tag])

      XCTAssertEqual(moment.title, "macOS")
      XCTAssertEqual(moment.content, "public API")
      XCTAssertEqual(participant.nickName, "nick")
      XCTAssertEqual(tag.title, "tag")
    }

    func testExportAPIIsAvailableOnMacOS() throws {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      let container = try ModelContainer(for: Schema.hDiaryScheme, configurations: [configuration])

      _ = RawDataCollection(modelContext: ModelContext(container))
    }
  }

#endif
