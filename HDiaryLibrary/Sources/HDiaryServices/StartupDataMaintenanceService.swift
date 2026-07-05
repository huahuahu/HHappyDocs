import Foundation
import HDiaryConstants
import HDiaryModel
import SwiftData

@MainActor
public struct StartupDataMaintenanceService {
  public struct LegacyImageMigrationResult: Equatable {
    public let convertedLegacyImages: Int
    public let deletedOrphanLegacyImages: Int
  }

  public struct MediaStorageUpdateResult: Equatable {
    public let updatedMediaItemIDs: [UUID]
  }

  public struct OrphanMediaCleanupResult: Equatable {
    public let deletedMediaItemIDs: [UUID]
    public let validMediaItemCount: Int
  }

  public struct DeletedMomentCleanupResult: Equatable {
    public let deletedMomentCount: Int
  }

  public init() {}

  public func runLoggingFailures(
    in modelContext: ModelContext,
    deletedMomentRetention: TimeInterval = 60 * 60 * 24 * 30
  ) {
    do {
      let result = try migrateLegacyImages(in: modelContext)
      Log.DB.migration.info("legacy image migration successed, converted: \(result.convertedLegacyImages, privacy: .public), deleted orphan legacy images: \(result.deletedOrphanLegacyImages, privacy: .public)")
    }
    catch {
      Log.DB.migration.error("Migrate legacy image fail \(error)")
    }

    do {
      let result = try updateMissingMediaStorageSizes(in: modelContext)
      Log.DB.migration.info("media item storage size update finished, updated count: \(result.updatedMediaItemIDs.count, privacy: .public)")
    }
    catch {
      Log.DB.migration.error("media item update storage size fail \(error)")
    }

    do {
      let result = try cleanUpOrphanMediaItems(in: modelContext)
      Log.data.info("Finish to clean up data, deleted media items: \(result.deletedMediaItemIDs, privacy: .public), valid media items: \(result.validMediaItemCount, privacy: .public)")
    }
    catch {
      Log.data.error("Failed to clean up data: \(error)")
    }

    do {
      let deleteTimeThreshold = Date(timeIntervalSinceNow: -deletedMomentRetention)
      let result = try cleanUpDeletedMoments(in: modelContext, deleteTimeThreshold: deleteTimeThreshold)
      Log.data.info("Finish to clean up deleted moments, deleted moments count: \(result.deletedMomentCount, privacy: .public)")
    }
    catch {
      Log.data.error("Failed to clean up deleted moments: \(error)")
    }
  }

  public func migrateLegacyImages(in modelContext: ModelContext) throws -> LegacyImageMigrationResult {
    let legacyImages = try modelContext.fetch(FetchDescriptor<HappyImage>())
    var convertedLegacyImages = 0
    var deletedOrphanLegacyImages = 0

    for image in legacyImages {
      if image.moment != nil {
        #if canImport(UIKit)
          image.updateThumbnail()
        #endif
        let mediaItem = MediaItem(image)
        mediaItem.moment = image.moment
        modelContext.insert(mediaItem)
        modelContext.delete(image)
        convertedLegacyImages += 1
        Log.DB.migration.info("update thumbnail for image \(image.uuid)")
      }
      else {
        modelContext.delete(image)
        deletedOrphanLegacyImages += 1
        Log.DB.migration.info("delete image  \(image.uuid) because no moments")
      }
    }

    try modelContext.save()
    return LegacyImageMigrationResult(
      convertedLegacyImages: convertedLegacyImages,
      deletedOrphanLegacyImages: deletedOrphanLegacyImages
    )
  }

  public func updateMissingMediaStorageSizes(in modelContext: ModelContext) throws -> MediaStorageUpdateResult {
    var updatedMediaItemIDs: [UUID] = []
    try modelContext.enumerate(
      FetchDescriptor<MediaItem>(),
      batchSize: 10,
      allowEscapingMutations: true
    ) { mediaItem in
      if mediaItem.storageSize == nil {
        mediaItem.updateStorageSizeIfNeeded()
        updatedMediaItemIDs.append(mediaItem.uuid)
        Log.DB.migration.info("media item \(mediaItem.uuid) update storage size successed")
      }
    }
    try modelContext.save()
    return MediaStorageUpdateResult(updatedMediaItemIDs: updatedMediaItemIDs)
  }

  public func cleanUpOrphanMediaItems(in modelContext: ModelContext) throws -> OrphanMediaCleanupResult {
    Log.data.info("Start to clean up data")
    var deletedMediaItemIDs: [UUID] = []
    var validMediaItemIDs: [UUID] = []

    try modelContext.enumerate(FetchDescriptor<MediaItem>(), batchSize: 5) { mediaItem in
      if mediaItem.moment == nil {
        deletedMediaItemIDs.append(mediaItem.uuid)
        Log.data.info("delete media item \(mediaItem.uuid, privacy: .public)")
        modelContext.delete(mediaItem)
      }
      else {
        validMediaItemIDs.append(mediaItem.uuid)
      }
    }

    try modelContext.save()
    return OrphanMediaCleanupResult(
      deletedMediaItemIDs: deletedMediaItemIDs,
      validMediaItemCount: validMediaItemIDs.count
    )
  }

  public func cleanUpDeletedMoments(
    in modelContext: ModelContext,
    deleteTimeThreshold: Date
  ) throws -> DeletedMomentCleanupResult {
    Log.data.info("Start to clean up deleted moments")
    let momentsCountBeforeDeletion = try modelContext.fetchCount(FetchDescriptor<Moment>())
    let predicate = #Predicate<Moment> {
      if $0.markedAsDelete {
        if let markedAsDeleteDate = $0.markedAsDeleteDate {
          return markedAsDeleteDate < deleteTimeThreshold
        }
        else {
          return false
        }
      }
      else {
        return false
      }
    }
    try modelContext.delete(model: Moment.self, where: predicate)
    try modelContext.save()
    let momentsCountAfterDeletion = try modelContext.fetchCount(FetchDescriptor<Moment>())
    return DeletedMomentCleanupResult(
      deletedMomentCount: momentsCountBeforeDeletion - momentsCountAfterDeletion
    )
  }
}

