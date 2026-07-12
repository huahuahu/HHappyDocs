#if os(iOS)

  @testable import HDiaryAppFeature
  import Foundation
  import HDiaryModel
  import ImageIO
  import SwiftData
  import UIKit
  import XCTest

  @MainActor
  final class WidgetSnapshotProjectorTests: XCTestCase {
    func testProjectBuildsBoundedDeduplicatedUnionAndFiltersDeletedMoments() async throws {
      let firstParticipantID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
      let secondParticipantID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
      let deletedID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000009999"))
      let participants = [
        WidgetParticipantSource(uuid: firstParticipantID, nickName: "A", avatarData: Data([1, 2, 3])),
        WidgetParticipantSource(uuid: secondParticipantID, nickName: "B", avatarData: Data([4, 5, 6])),
      ]
      var moments = [WidgetMomentSource]()
      for index in 0 ..< 10 {
        try moments.append(WidgetMomentSource(
          uuid: XCTUnwrap(UUID(uuidString: String(format: "00000000-0000-0000-0001-%012d", index))),
          timestamp: Date(timeIntervalSince1970: TimeInterval(1000 - index)),
          title: "A-\(index)",
          participantIDs: [firstParticipantID],
          isDeleted: false
        ))
        try moments.append(WidgetMomentSource(
          uuid: XCTUnwrap(UUID(uuidString: String(format: "00000000-0000-0000-0002-%012d", index))),
          timestamp: Date(timeIntervalSince1970: TimeInterval(900 - index)),
          title: "B-\(index)",
          participantIDs: [secondParticipantID],
          isDeleted: false
        ))
      }
      for index in 0 ..< 3 {
        try moments.append(WidgetMomentSource(
          uuid: XCTUnwrap(UUID(uuidString: String(format: "00000000-0000-0000-0003-%012d", index))),
          timestamp: Date(timeIntervalSince1970: TimeInterval(800 - index)),
          title: "Global-\(index)",
          participantIDs: [],
          isDeleted: false
        ))
      }
      moments.append(WidgetMomentSource(
        uuid: deletedID,
        timestamp: Date(timeIntervalSince1970: 2000),
        title: "Deleted",
        participantIDs: [firstParticipantID, secondParticipantID],
        isDeleted: true
      ))

      let snapshot = await WidgetSnapshotProjector.project(
        participants: participants,
        moments: moments,
        limit: 8,
        thumbnail: { data in data.map { Data($0.prefix(2)) } }
      )

      XCTAssertEqual(snapshot.participants.count, 2)
      XCTAssertTrue(snapshot.participants.allSatisfy { ($0.avatarThumbnailData?.count ?? 0) <= 2 })
      XCTAssertFalse(snapshot.moments.contains { $0.uuid == deletedID })
      XCTAssertEqual(Set(snapshot.moments.map(\.uuid)).count, snapshot.moments.count)
      XCTAssertLessThanOrEqual(snapshot.moments.count, participants.count * 8 + 8)
      XCTAssertEqual(snapshot.moments.filter { $0.participantIDs.contains(firstParticipantID) }.count, 8)
      XCTAssertEqual(snapshot.moments.filter { $0.participantIDs.contains(secondParticipantID) }.count, 8)
    }

    func testProjectUsesDeterministicParticipantAndMomentTieBreakers() async throws {
      let firstID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
      let secondID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
      let timestamp = Date(timeIntervalSince1970: 1000)
      let participants = [
        WidgetParticipantSource(uuid: secondID, nickName: "Same", avatarData: nil),
        WidgetParticipantSource(uuid: firstID, nickName: "Same", avatarData: nil),
      ]
      let moments = [
        WidgetMomentSource(
          uuid: secondID,
          timestamp: timestamp,
          title: "Second",
          participantIDs: [],
          isDeleted: false
        ),
        WidgetMomentSource(
          uuid: firstID,
          timestamp: timestamp,
          title: "First",
          participantIDs: [],
          isDeleted: false
        ),
      ]

      let snapshot = await WidgetSnapshotProjector.project(
        participants: participants,
        moments: moments,
        limit: 8,
        thumbnail: { $0 }
      )

      XCTAssertEqual(snapshot.participants.map(\.uuid), [firstID, secondID])
      XCTAssertEqual(snapshot.moments.map(\.uuid), [firstID, secondID])
    }

    func testLiveThumbnailerDownsamplesLongestEdgeTo64Pixels() async throws {
      let sourceData = makeImageData(width: 512, height: 256)

      let generatedThumbnail = await WidgetAvatarThumbnailer.thumbnailData(
        from: sourceData,
        maxPixelSize: 64
      )
      let thumbnailData = try XCTUnwrap(generatedThumbnail)
      let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(thumbnailData as CFData, nil))
      let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))

      XCTAssertEqual(max(image.width, image.height), 64)
      XCTAssertEqual(image.width, 64)
      XCTAssertEqual(image.height, 32)
    }

    func testLiveThumbnailerReturnsNilForMissingOrInvalidData() async {
      let missingThumbnail = await WidgetAvatarThumbnailer.thumbnailData(from: nil, maxPixelSize: 64)
      let invalidThumbnail = await WidgetAvatarThumbnailer.thumbnailData(
        from: Data("not an image".utf8),
        maxPixelSize: 64
      )

      XCTAssertNil(missingThumbnail)
      XCTAssertNil(invalidThumbnail)
    }

    func testBuilderMapsMarkedAsDeleteToDeletedSourceSemantics() async throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      let participant = Participant.create(name: "Participant", nickName: "P")
      let activeMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 1000))
      activeMoment.updateTitle("Active")
      activeMoment.updateParticipants([participant])
      let deletedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 2000))
      deletedMoment.updateTitle("Deleted")
      deletedMoment.updateParticipants([participant])
      deletedMoment.markAsDelete()
      context.insert(participant)
      context.insert(activeMoment)
      context.insert(deletedMoment)
      try context.save()

      let snapshot = try await MainStoreWidgetSnapshotBuilder(container: container).build()

      XCTAssertEqual(snapshot.participants.map(\.uuid), [participant.uuid])
      XCTAssertEqual(snapshot.participants.map(\.nickName), [participant.nickName])
      XCTAssertEqual(snapshot.moments.map(\.uuid), [activeMoment.uuid])
      XCTAssertEqual(snapshot.moments.map(\.title), [activeMoment.title])
      XCTAssertEqual(snapshot.moments.map(\.participantIDs), [[participant.uuid]])
      XCTAssertFalse(snapshot.moments.contains { $0.uuid == deletedMoment.uuid })
    }

    private func makeImageData(width: CGFloat, height: CGFloat) -> Data {
      let format = UIGraphicsImageRendererFormat()
      format.opaque = true
      format.scale = 1
      return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        .jpegData(withCompressionQuality: 1) { context in
          UIColor.systemBlue.setFill()
          context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
  }

#endif
