import Foundation
import SwiftData
@testable import HDiaryWidgetData
import XCTest

final class WidgetSnapshotContainerTests: XCTestCase {
  func testReaderAndWriterUseDedicatedNonCloudStore() {
    let url = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString)
      .appending(path: "widget-snapshot.sqlite")

    let writer = WidgetSnapshotContainer.configuration(url: url, allowsSave: true)
    let reader = WidgetSnapshotContainer.configuration(url: url, allowsSave: false)

    XCTAssertEqual(writer.url, url)
    XCTAssertEqual(reader.url, url)
    XCTAssertTrue(writer.allowsSave)
    XCTAssertFalse(reader.allowsSave)
    XCTAssertNil(writer.cloudKitContainerIdentifier)
    XCTAssertNil(reader.cloudKitContainerIdentifier)
  }

  func testSnapshotValuesContainOnlyWidgetFields() {
    let participant = WidgetParticipantValue(
      uuid: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
      nickName: "Tiger",
      avatarThumbnailData: Data([1, 2, 3])
    )
    let moment = WidgetMomentValue(
      uuid: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
      timestamp: Date(timeIntervalSince1970: 100),
      title: "Moment",
      participantIDs: [participant.uuid]
    )

    XCTAssertEqual(WidgetSnapshotValue(participants: [participant], moments: [moment]).moments, [moment])
  }
}
