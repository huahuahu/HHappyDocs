@testable import HDiaryServices
import HDiaryModel
import SwiftData
import XCTest

@MainActor
final class StartupDataMaintenanceServiceTests: XCTestCase {
  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: Schema.hDiaryScheme, configurations: [configuration])
    return ModelContext(container)
  }

  func testMigrateLegacyImagesCreatesMediaItemsAndDeletesHappyImages() throws {
    let context = try makeContext()
    let moment = Moment.create(timestamp: Date())
    let legacyImage = HappyImage.create()
    moment.updateLegacyImages([legacyImage])
    context.insert(moment)
    context.insert(legacyImage)
    try context.save()

    let result = try StartupDataMaintenanceService().migrateLegacyImages(in: context)

    XCTAssertEqual(result.convertedLegacyImages, 1)
    XCTAssertEqual(result.deletedOrphanLegacyImages, 0)
    XCTAssertEqual(try context.fetchCount(FetchDescriptor<HappyImage>()), 0)
    XCTAssertEqual(try context.fetchCount(FetchDescriptor<MediaItem>()), 1)
    let mediaItem = try XCTUnwrap(try context.fetch(FetchDescriptor<MediaItem>()).first)
    XCTAssertNotNil(mediaItem.moment)
  }

  func testMigrateLegacyImagesDeletesOrphanHappyImages() throws {
    let context = try makeContext()
    context.insert(HappyImage.create())
    try context.save()

    let result = try StartupDataMaintenanceService().migrateLegacyImages(in: context)

    XCTAssertEqual(result.convertedLegacyImages, 0)
    XCTAssertEqual(result.deletedOrphanLegacyImages, 1)
    XCTAssertEqual(try context.fetchCount(FetchDescriptor<HappyImage>()), 0)
    XCTAssertEqual(try context.fetchCount(FetchDescriptor<MediaItem>()), 0)
  }

  func testCleanUpOrphanMediaItemsDeletesOnlyItemsWithoutMoment() throws {
    let context = try makeContext()
    let moment = Moment.create(timestamp: Date())
    let attachedMediaItem = MediaItem(
      data: Data([1]),
      moment: moment,
      mediaType: .image,
      pathExtension: "heic",
      thumbnailData150px: nil,
      thumbnailData500px: nil,
      thumbnailData1000px: nil
    )
    let orphanMediaItem = MediaItem(
      data: Data([2]),
      mediaType: .image,
      pathExtension: "heic",
      thumbnailData150px: nil,
      thumbnailData500px: nil,
      thumbnailData1000px: nil
    )
    context.insert(moment)
    context.insert(attachedMediaItem)
    context.insert(orphanMediaItem)
    try context.save()

    let result = try StartupDataMaintenanceService().cleanUpOrphanMediaItems(in: context)

    XCTAssertEqual(result.deletedMediaItemIDs, [orphanMediaItem.uuid])
    XCTAssertEqual(result.validMediaItemCount, 1)
    let remainingItems = try context.fetch(FetchDescriptor<MediaItem>())
    XCTAssertEqual(remainingItems.map(\.uuid), [attachedMediaItem.uuid])
  }

  func testCleanUpDeletedMomentsDeletesOnlyMarkedMomentsBeforeThreshold() throws {
    let context = try makeContext()
    let deletedMoment = Moment.create(timestamp: Date())
    deletedMoment.markAsDelete()
    let activeMoment = Moment.create(timestamp: Date())
    context.insert(deletedMoment)
    context.insert(activeMoment)
    try context.save()

    let result = try StartupDataMaintenanceService().cleanUpDeletedMoments(
      in: context,
      deleteTimeThreshold: Date.distantFuture
    )

    XCTAssertEqual(result.deletedMomentCount, 1)
    let remainingMoments = try context.fetch(FetchDescriptor<Moment>())
    XCTAssertEqual(remainingMoments.map(\.uuid), [activeMoment.uuid])
  }
}

