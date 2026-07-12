#if os(iOS)

  import HDiaryConstants
  import HDiaryModel
  import HDiaryWidgetData
  import HDiaryWidgetIntents
  import UIKit
  import XCTest

  final class MomentWidgetIntentTests: XCTestCase {
    @MainActor func testWidgetIntentsDeclaresAppIntentsPackage() {
      _ = HDiaryWidgetIntentsAppIntentsPackage()
    }

    func testSelectedParticipantIDUsesStoredUUIDString() {
      let participantID = UUID(uuidString: "9D3C891B-537F-4935-9D21-B763792E49D5").unsafelyUnwrapped

      let intent = MomentWidgetIntent(participantID: participantID.uuidString)

      XCTAssertEqual(intent.participantID, participantID.uuidString)
      XCTAssertEqual(intent.selectedParticipantID, participantID)
    }

    func testSelectedParticipantIDIsNilForInvalidStoredString() {
      let intent = MomentWidgetIntent(participantID: "not-a-uuid")

      XCTAssertEqual(intent.participantID, "not-a-uuid")
      XCTAssertNil(intent.selectedParticipantID)
    }

    func testSelectedParticipantIDSupportsAllParticipantsSentinelString() {
      let intent = MomentWidgetIntent(participantID: UUID.null.uuidString)

      XCTAssertEqual(intent.participantID, UUID.null.uuidString)
      XCTAssertEqual(intent.selectedParticipantID, .null)
    }

    @MainActor func testMomentWidgetDataSourceReadsIsolatedSnapshotStore() async throws {
      let firstParticipantID = try XCTUnwrap(
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")
      )
      let secondParticipantID = try XCTUnwrap(
        UUID(uuidString: "00000000-0000-0000-0000-000000000002")
      )
      let firstMomentID = try XCTUnwrap(
        UUID(uuidString: "00000000-0000-0000-0001-000000000001")
      )
      let sharedMomentID = try XCTUnwrap(
        UUID(uuidString: "00000000-0000-0000-0001-000000000002")
      )
      let secondMomentID = try XCTUnwrap(
        UUID(uuidString: "00000000-0000-0000-0001-000000000003")
      )
      let storeURL = temporaryStoreURL()
      let writerContainer = try WidgetSnapshotContainer.makeWriterContainer(at: storeURL)
      let writer = WidgetSnapshotStore(modelContainer: writerContainer)
      try await writer.replace(with: WidgetSnapshotValue(
        participants: [
          WidgetParticipantValue(
            uuid: secondParticipantID,
            nickName: "Beta",
            avatarThumbnailData: nil
          ),
          WidgetParticipantValue(
            uuid: firstParticipantID,
            nickName: "Alpha",
            avatarThumbnailData: nil
          ),
        ],
        moments: [
          WidgetMomentValue(
            uuid: secondMomentID,
            timestamp: Date(timeIntervalSince1970: 100),
            title: "Second",
            participantIDs: [secondParticipantID]
          ),
          WidgetMomentValue(
            uuid: sharedMomentID,
            timestamp: Date(timeIntervalSince1970: 200),
            title: "Shared",
            participantIDs: [firstParticipantID, secondParticipantID]
          ),
          WidgetMomentValue(
            uuid: firstMomentID,
            timestamp: Date(timeIntervalSince1970: 300),
            title: "First",
            participantIDs: [firstParticipantID]
          ),
        ]
      ))

      let readerContainer = try WidgetSnapshotContainer.makeReaderContainer(at: storeURL)
      let dataSource = MomentWidgetDataSource(modelContainer: readerContainer)

      let participants = try dataSource.fetchParticipants()
      let selectedMoments = try dataSource.fetchMoments(participantID: firstParticipantID)
      let allMoments = try dataSource.fetchMoments(participantID: .null)

      XCTAssertEqual(participants.map(\.uuid), [firstParticipantID, secondParticipantID])
      XCTAssertEqual(selectedMoments.map(\.uuid), [firstMomentID, sharedMomentID])
      XCTAssertEqual(allMoments.count, 3)
      XCTAssertNotEqual(
        readerContainer.configurations.first?.url,
        HDiaryContainer.iCloudConfiguration.url
      )
    }

    @MainActor func testParticipantEntityMapsSnapshotThumbnailAndNickname() throws {
      let participantID = try XCTUnwrap(
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")
      )
      let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 3, height: 2)).image { context in
        UIColor.systemPink.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 3, height: 2))
      }
      let thumbnailData = try XCTUnwrap(sourceImage.pngData())

      let entity = ParticipantEntity(from: WidgetParticipantValue(
        uuid: participantID,
        nickName: "Tiger",
        avatarThumbnailData: thumbnailData
      ))
      let decodedThumbnail = try XCTUnwrap(UIImage(data: thumbnailData))

      XCTAssertEqual(entity.id, participantID)
      XCTAssertEqual(entity.name, "Tiger")
      XCTAssertEqual(entity.avatar.size, decodedThumbnail.size)
      XCTAssertEqual(entity.avatar.pngData(), decodedThumbnail.pngData())
    }

    @MainActor func testParticipantEntityUsesStableFallbackForMissingOrInvalidThumbnail() {
      let missingThumbnail = ParticipantEntity(from: WidgetParticipantValue(
        uuid: UUID(),
        nickName: "Missing",
        avatarThumbnailData: nil
      ))
      let invalidThumbnail = ParticipantEntity(from: WidgetParticipantValue(
        uuid: UUID(),
        nickName: "Invalid",
        avatarThumbnailData: Data([0x00, 0x01, 0x02])
      ))

      XCTAssertGreaterThan(missingThumbnail.avatar.size.width, 0)
      XCTAssertGreaterThan(missingThumbnail.avatar.size.height, 0)
      XCTAssertEqual(missingThumbnail.avatar.pngData(), invalidThumbnail.avatar.pngData())
    }

    private func temporaryStoreURL() -> URL {
      let directory = FileManager.default.temporaryDirectory.appending(
        path: UUID().uuidString,
        directoryHint: .isDirectory
      )
      addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
      return directory.appending(path: "widget-snapshot.sqlite")
    }
  }

#endif
