import Foundation
import SwiftData
@testable import HDiaryWidgetData
import XCTest

final class WidgetSnapshotStoreTests: XCTestCase {
  func testReplaceUpdatesExistingRowsAndDeletesStaleRows() async throws {
    let url = temporaryStoreURL()
    let container = try WidgetSnapshotContainer.makeWriterContainer(at: url)
    let store = WidgetSnapshotStore(modelContainer: container)

    let first = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Old"), participant(id: 2, name: "Stale")],
      moments: [moment(id: 1, title: "Old"), moment(id: 2, title: "Stale")]
    )
    let second = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "New")],
      moments: [moment(id: 1, title: "New")]
    )

    try await store.replace(with: first)
    try await store.replace(with: second)

    let persisted = try await store.snapshot()
    XCTAssertEqual(persisted, second)
  }

  @MainActor
  func testReaderContainerReadsWriterDataAndRejectsSave() async throws {
    let url = temporaryStoreURL()
    let writerContainer = try WidgetSnapshotContainer.makeWriterContainer(at: url)
    let store = WidgetSnapshotStore(modelContainer: writerContainer)
    try await store.replace(
      with: .init(participants: [participant(id: 1, name: "Tiger")], moments: [])
    )

    let readerContainer = try WidgetSnapshotContainer.makeReaderContainer(at: url)
    let context = ModelContext(readerContainer)
    XCTAssertEqual(
      try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>()).map(\.nickName),
      ["Tiger"]
    )

    context.insert(
      WidgetParticipantSnapshot(uuid: UUID(), nickName: "Forbidden", avatarThumbnailData: nil)
    )
    XCTAssertThrowsError(try context.save())
  }

  func testFailedReplaceKeepsPreviouslyPersistedSnapshot() async throws {
    let url = temporaryStoreURL()
    let writerContainer = try WidgetSnapshotContainer.makeWriterContainer(at: url)
    let writerStore = WidgetSnapshotStore(modelContainer: writerContainer)
    let original = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Original")],
      moments: [moment(id: 1, title: "Original")]
    )
    try await writerStore.replace(with: original)

    let readerContainer = try WidgetSnapshotContainer.makeReaderContainer(at: url)
    let readerStore = WidgetSnapshotStore(modelContainer: readerContainer)
    let replacement = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Replacement")],
      moments: [moment(id: 1, title: "Replacement")]
    )

    do {
      try await readerStore.replace(with: replacement)
      XCTFail("Expected replacement through a read-only container to fail")
    } catch {}

    let verificationContainer = try WidgetSnapshotContainer.makeReaderContainer(at: url)
    let verificationStore = WidgetSnapshotStore(modelContainer: verificationContainer)
    let persisted = try await verificationStore.snapshot()
    XCTAssertEqual(persisted, original)
  }

  private func fixedUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
  }

  private func participant(id: Int, name: String) -> WidgetParticipantValue {
    WidgetParticipantValue(uuid: fixedUUID(id), nickName: name, avatarThumbnailData: nil)
  }

  private func moment(id: Int, title: String) -> WidgetMomentValue {
    WidgetMomentValue(
      uuid: fixedUUID(1_000 + id),
      timestamp: Date(timeIntervalSince1970: TimeInterval(id)),
      title: title,
      participantIDs: [fixedUUID(1)]
    )
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
