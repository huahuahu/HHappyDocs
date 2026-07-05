//
//  Moment.swift
//
//
//  Created by tigerguo on 2024/4/3.
//

import Foundation
import HDiaryConstants
import SwiftData

@Model
public final class Moment {
//    @available(iOS 18.0, *)
//    #Index<Moment>([\.timestamp])

  public private(set) var timestamp: Date = Date.distantPast

  // Not used any more
  private var lastModifyTimestamp: Date = Date.distantPast

  public private(set) var title: String = ""
  public private(set) var content: String = ""
  @Relationship(deleteRule: .cascade, inverse: \MediaItem.moment) public private(set) var mediaItems: [MediaItem]? = []
  /// Images from legacy schema
  public private(set) var images: [HappyImage]? = []
  public private(set) var participants: [Participant]? = []
  private(set) var tags: [Tag]? = []
  public private(set) var uuid = UUID()
  // range from 1 to 5. 0 means not set
  public private(set) var rating: Int = 0

  // The isDelete is incorrect.
  // https://www.hackingwithswift.com/quick-start/swiftdata/how-to-check-whether-a-swiftdata-model-object-has-been-deleted
  public private(set) var markedAsDelete: Bool = false
  public private(set) var markedAsDeleteDate: Date?

  // For recommendation
  public var lastVisitDate: Date?
  public private(set) var visitCount: Int = 0

  public static func create(timestamp: Date) -> Moment {
    Self(timestamp: timestamp)
  }

  init(timestamp: Date) {
    self.timestamp = timestamp
    self.lastModifyTimestamp = timestamp
    self.uuid = UUID()
    visitCount = 1
    lastVisitDate = Date()
  }

  public func increaseVisitCount() {
    self.visitCount += 1
  }

//  private func updateLastModifyTimeStamp() {
//    self.lastModifyTimestamp = Date()
//  }

  public func updateTimeStamp(_ newTimeStamp: Date) {
    self.timestamp = newTimeStamp
  }

  public func updateTags(_ newTags: [Tag]) {
    self.tags = newTags
  }

  public func updateTitle(_ title: String) {
    self.title = title
  }

  public func updateContent(_ content: String) {
    self.content = content
  }

  public func addMedia(_ mediaItem: MediaItem) {
    mediaItem.moment = self
  }

  public func updateMedias(_ mediaItems: [MediaItem]?) {
    guard let mediaItems else { return }

    for mediaItem in mediaItems {
      mediaItem.moment = self
    }
    let newMediaItemIds: Set<UUID> = mediaItems.reduce(into: []) {
      $0.insert($1.uuid)
    }
    Log.data.debug("newMediaItemIds are \(newMediaItemIds)")

    self.mediaItems?.forEach({ currentMediaItem in
      guard newMediaItemIds.contains(currentMediaItem.uuid) else {
        currentMediaItem.moment = nil
        modelContext?.delete(currentMediaItem)
        Log.data.debug("deleted media item \(currentMediaItem.uuid) from moment \(self.uuid)")
        return
      }
    })
  }

  /// Handle legacy image
  public func updateLegacyImages(_ images: [HappyImage]?) {
    guard let images else { return }
    for image in images {
      image.moment = self
    }
    let newImageIds: Set<UUID> = images.reduce(into: []) {
      $0.insert($1.uuid)
    }
    Log.data.debug("newImageIds are \(newImageIds)")

    self.images?.forEach({ currentImage in
      guard newImageIds.contains(currentImage.uuid) else {
        currentImage.moment = nil
        modelContext?.delete(currentImage)
        Log.data.debug("deleted legacy image \(currentImage.uuid) from moment \(self.uuid)")
        return
      }
    })
  }

  public func updateParticipants(_ participants: [Participant]?) {
    self.participants = participants
  }

  public func markAsDelete() {
    updateParticipants([])
    updateTags([])
    updateMedias([])
    updateLegacyImages([])
    markedAsDelete = true
    markedAsDeleteDate = Date()
  }

  public func updateRating(_ newRating: Int) {
    self.rating = newRating
  }

  public func getLocalizedComparedTags() -> [Tag]? {
    tags?.sorted { $0.text.localizedStandardCompare($1.text) == .orderedAscending }
  }

  public func getMediaStorageSize() -> Int {
    mediaItems?
      .reduce(into: 0) { result, mediaItem in
        result += mediaItem.storageSize ?? 0
      } ?? 0
  }
}

extension Moment: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(timestamp, forKey: .timestamp)
    try container.encode(lastModifyTimestamp, forKey: .lastModifyTimestamp)
    try container.encode(title, forKey: .title)
    try container.encode(content, forKey: .content)
    try container.encode(uuid, forKey: .uuid)
    try container.encode(rating, forKey: .rating)

    // relationship
    try container.encode(mediaItems?.map { $0.uuid }, forKey: .mediaItems)
    try container.encode(images?.map { $0.uuid }, forKey: .legacyImages)
    try container.encode(participants?.map { $0.uuid }, forKey: .participants)
    try container.encode(tags?.map { $0.uuid }, forKey: .tags)
  }

  private enum CodingKeys: CodingKey, CaseIterable {
    case timestamp
    case lastModifyTimestamp
    case title
    case content
    case uuid
    case rating

    case mediaItems
    case legacyImages
    case participants
    case tags
  }
}
