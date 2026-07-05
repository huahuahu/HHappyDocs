//
//  MediaItem.swift
//
//
//  Created by tigerguo on 2023/12/10.
//

import Foundation
import HDiaryConstants
import SwiftData

#if canImport(UIKit)
  import HMedia
  import UIKit
#endif

@Model
public final class MediaItem {
  public enum MediaType: String, Sendable {
    case image
    case gif
    case video
  }

  @Attribute(.externalStorage) public private(set) var data: Data = Data()

  @Attribute(.externalStorage) public private(set) var thumbnailData150px: Data?
  @Attribute(.externalStorage) public private(set) var thumbnailData500px: Data?
  @Attribute(.externalStorage) public private(set) var thumbnailData1000px: Data?
  public private(set) var uuid = UUID()
  public var moment: Moment?
  public private(set) var createDate = Date()
  public private(set) var pathExtension: String = ""
  private var mediaTypeValue: String?
  public private(set) var storageSize: Int?

  public var mediaType: MediaType? {
    if let mediaTypeValue {
      return MediaType(rawValue: mediaTypeValue)
    }
    else {
      return nil
    }
  }

  public init(
    data: Data,
    moment: Moment? = nil,
    mediaType: MediaType,
    pathExtension: String,
    thumbnailData150px: Data?,
    thumbnailData500px: Data?,
    thumbnailData1000px: Data?
  ) {
    self.data = data
    self.uuid = UUID()
    self.moment = moment
    self.createDate = Date()
    self.mediaTypeValue = mediaType.rawValue
    self.pathExtension = pathExtension
    self.thumbnailData150px = thumbnailData150px
    self.thumbnailData500px = thumbnailData500px
    self.thumbnailData1000px = thumbnailData1000px
    self.storageSize = data.count
    Log.data.info("Created mediaItem \(self.uuid)")
  }

  public func updateStorageSizeIfNeeded() {
    if self.storageSize == nil {
      self.storageSize = data.count
    }
  }

  public init(_ happyImage: HappyImage) {
    self.data = happyImage.data
    self.uuid = happyImage.uuid
    self.createDate = happyImage.creationDate
    self.mediaTypeValue = MediaType.image.rawValue
    self.pathExtension = "heic"
    self.thumbnailData150px = happyImage.thumbnailData150px
    self.thumbnailData500px = happyImage.thumbnailData500px
    self.thumbnailData1000px = happyImage.thumbnailData1000px
    self.storageSize = happyImage.data.count
  }
}

extension MediaItem: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(uuid, forKey: .uuid)
    try container.encode(createDate, forKey: .createDate)
    try container.encode(pathExtension, forKey: .pathExtension)
    try container.encode(mediaTypeValue, forKey: .mediaTypeValue)
    try container.encode(storageSize, forKey: .storageSize)
    try container.encode(data, forKey: .data)

    // relationship
    try container.encode(moment?.uuid, forKey: .moment)
  }

  private enum CodingKeys: CodingKey, CaseIterable {
    case uuid
    case createDate
    case pathExtension
    case mediaTypeValue
    case storageSize
    case data

    case moment
  }
}

// Legacy code
@Model
public final class HappyImage {
  public static func create() -> HappyImage {
    return Self()
  }

  public private(set) var data: Data = Data()
  public private(set) var uuid = UUID()
  public var moment: Moment?
  public private(set) var creationDate = Date()
  @Attribute(.externalStorage) public private(set) var thumbnailData150px: Data?
  @Attribute(.externalStorage) public private(set) var thumbnailData500px: Data?
  @Attribute(.externalStorage) public private(set) var thumbnailData1000px: Data?

  init() {
    self.uuid = UUID()
    self.data = Data()
    creationDate = Date()
  }

  #if canImport(UIKit)
    public var uiImage: UIImage? {
      UIImage(data: data)
    }

    public func updateThumbnail() {
      if thumbnailData150px == nil {
        thumbnailData150px = try? UIImage.downsample(imageData: data, to: CGSize(width: 150, height: 150))
      }
      if thumbnailData500px == nil {
        thumbnailData500px = try? UIImage.downsample(imageData: data, to: CGSize(width: 500, height: 500))
      }

      if thumbnailData1000px == nil {
        thumbnailData1000px = try? UIImage.downsample(imageData: data, to: CGSize(width: 1000, height: 1000))
      }
    }
  #endif
}

extension HappyImage: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(uuid, forKey: .uuid)
    try container.encode(creationDate, forKey: .creationDate)
    try container.encode(data, forKey: .data)

    // relationship
    try container.encode(moment?.uuid, forKey: .moment)
  }

  private enum CodingKeys: CodingKey, CaseIterable {
    case uuid
    case creationDate
    case data

    case moment
  }
}
