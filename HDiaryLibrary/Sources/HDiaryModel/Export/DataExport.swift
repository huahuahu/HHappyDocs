//
//  DataExport.swift
//
//
//  Created by tigerguo on 2024/4/9.
//

import CoreTransferable
import Foundation
import HDiaryConstants
import HFoundation
import SwiftData

public struct RawDataCollection: Transferable {
  private enum Constants {
    static let exportFolderName = "RawDataExport"
  }

  let modelContext: ModelContext

  public static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .appleArchive, shouldAllowToOpenInPlace: false) { item in
      Log.DB.export.info("exporting all data as file")
      let url = try await item.writeToTempFile()
      return SentTransferredFile(url)
    }

//    DataRepresentation(exportedContentType: .json, exporting: { item in
//      Log.DB.export.info("exporting all data as data")
    ////        try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
//      let data = try await item.prepareData()
//      return data
//    })

//      DataRepresentation(exportedContentType: .zip, exporting: { item in
//        Log.DB.export.info("exporting all data as data")
//        let data = try await item.prepareData()
//        return data
//      })
  }

  public init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

//  func prepareData() throws -> Data {
//    let moments = try modelContext.fetch(FetchDescriptor<Moment>())
//    let participants = try modelContext.fetch(FetchDescriptor<Participant>())
//    let tags = try modelContext.fetch(FetchDescriptor<Tag>())
//
//    let mediaItems = try modelContext.fetch(FetchDescriptor<MediaItem>())
//    let happyImages = try modelContext.fetch(FetchDescriptor<HappyImage>())
//
//    struct Model: Encodable {
//      let moments: [Moment]
//      let participants: [Participant]
//      let tags: [Tag]
//      let mediaItems: [MediaItem]
//      let happyImages: [HappyImage]
//    }
//
//    let model = Model(moments: moments, participants: participants, tags: tags, mediaItems: mediaItems, happyImages: happyImages)
//
//    return try JSONEncoder().encode(model)
//  }

  @MainActor
  func writeToTempFile() throws -> URL {
    clearExportFolder()
    let uuid = UUID().uuidString
    let fileManager = FileManager.default
    let encoder = JSONEncoder()
    let sourceFolderURL = URL(filePath: NSTemporaryDirectory()).appending(path: "RawDataExport", directoryHint: .isDirectory).appendingPathComponent(uuid)
    let destinationArchiveFile = sourceFolderURL.appendingPathExtension(for: .appleArchive)
    let batchSize = 1

    do {
      Log.DB.export.info("sourceFolderURL url is \(sourceFolderURL)")
      try fileManager.createDirectory(at: sourceFolderURL, withIntermediateDirectories: true, attributes: nil)

      // write Models
      let modelFolder = sourceFolderURL.appending(path: "moments", directoryHint: .isDirectory)
      try fileManager.createDirectory(at: modelFolder, withIntermediateDirectories: true, attributes: nil)
      try autoreleasepool {
        try modelContext.enumerate(FetchDescriptor<Moment>(), batchSize: batchSize) { moment in
          try autoreleasepool {
            Log.DB.export.debug("writing moment \(moment.uuid)")
            let data = try encoder.encode(moment)
            let url = modelFolder.appending(path: moment.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension(for: .json)
            try data.write(to: url, options: .atomic)
          }
        }
      }

      // write participants
      let participantFolder = sourceFolderURL.appending(path: "participants", directoryHint: .isDirectory)
      try fileManager.createDirectory(at: participantFolder, withIntermediateDirectories: true, attributes: nil)
      try modelContext.enumerate(FetchDescriptor<Participant>(), batchSize: batchSize) { participant in
        try autoreleasepool {
          Log.DB.export.debug("writing participant \(participant.uuid)")
          let data = try encoder.encode(participant)
          let url = participantFolder.appending(path: participant.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension(for: .json)
          try data.write(to: url, options: .atomic)
        }
      }

      // write tags
      let tagFolder = sourceFolderURL.appending(path: "tags", directoryHint: .isDirectory)
      try fileManager.createDirectory(at: tagFolder, withIntermediateDirectories: true, attributes: nil)
      try modelContext.enumerate(FetchDescriptor<Tag>(), batchSize: batchSize) { tag in
        try autoreleasepool {
          Log.DB.export.debug("writing tag \(tag.uuid)")
          let data = try encoder.encode(tag)
          let url = tagFolder.appending(path: tag.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension(for: .json)
          try data.write(to: url, options: .atomic)
        }
      }

      // write mediaItems
      let mediaFolder = sourceFolderURL.appending(path: "Medias", directoryHint: .isDirectory)
      try fileManager.createDirectory(at: mediaFolder, withIntermediateDirectories: true, attributes: nil)
      try modelContext.enumerate(FetchDescriptor<MediaItem>(), batchSize: batchSize) { mediaItem in
        try autoreleasepool {
          Log.DB.export.debug("writing mediaItem \(mediaItem.uuid)")
          let mediaExportItem = MeidaExportItem(mediaItem: mediaItem)
          let data = try encoder.encode(mediaExportItem)
          let url = mediaFolder.appending(path: mediaItem.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension(for: .json)
          try data.write(to: url, options: .atomic)

          let mediaUrl = mediaFolder.appending(path: mediaItem.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension(mediaExportItem.pathExtension)
          try mediaExportItem.data.write(to: mediaUrl, options: .atomic)
        }
      }

      // write happyImages
      try modelContext.enumerate(FetchDescriptor<HappyImage>(), batchSize: batchSize) { happyImage in
        try autoreleasepool {
          Log.DB.export.debug("writing happyImage \(happyImage.uuid)")
          let mediaExportItem = MeidaExportItem(happyImage: happyImage)
          let data = try encoder.encode(mediaExportItem)
          let url = mediaFolder.appending(path: happyImage.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension(for: .json)
          try data.write(to: url, options: .atomic)

          let mediaUrl = mediaFolder.appending(path: happyImage.uuid.uuidString, directoryHint: .notDirectory).appendingPathExtension("heic")
          try mediaExportItem.data.write(to: mediaUrl, options: .atomic)
        }
      }

      try HCompress.archiveFolder(sourceFolderURL, to: destinationArchiveFile)
    }
    catch {
      Log.DB.export.error("Export raw data fail, \(error)")
    }

    return destinationArchiveFile
  }

  @MainActor
  private func clearExportFolder() {
    let folder = FileManager.default.temporaryDirectory.appending(path: Constants.exportFolderName, directoryHint: .isDirectory)
    do {
      try FileManager.default.removeItem(at: folder)
      Log.DB.export.info("clear export folder success \(folder.path(percentEncoded: false))")
    }
    catch {
      Log.DB.export.error("clear export folder error \(error)")
    }
  }
}

private struct MeidaExportItem: Encodable {
  var data: Data = Data()
  private(set) var uuid = UUID()
  private(set) var createDate = Date()
  private(set) var pathExtension: String = ""
  private var mediaTypeValue: String?
  var momentID: UUID?

  init(mediaItem: MediaItem
  ) {
    self.data = mediaItem.data
    self.uuid = mediaItem.uuid
    self.momentID = mediaItem.moment?.uuid
    self.createDate = mediaItem.createDate
    self.mediaTypeValue = mediaItem.mediaType?.rawValue
    self.pathExtension = mediaItem.pathExtension
  }

  init(happyImage: HappyImage
  ) {
    self.data = happyImage.data
    self.uuid = happyImage.uuid
    self.momentID = happyImage.moment?.uuid
    self.createDate = happyImage.creationDate
    self.mediaTypeValue = "image"
    self.pathExtension = "heic"
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(uuid, forKey: .uuid)
    try container.encode(createDate, forKey: .createDate)
    try container.encode(pathExtension, forKey: .pathExtension)
    try container.encode(mediaTypeValue, forKey: .mediaTypeValue)
    try container.encode(momentID, forKey: .momentID)
  }

  private enum CodingKeys: CodingKey, CaseIterable {
    case uuid
    case createDate
    case pathExtension
    case mediaTypeValue

    case momentID
  }
}
