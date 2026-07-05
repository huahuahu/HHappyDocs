//
//  HMediaItem.swift
//
//
//  Created by tigerguo on 2023/12/5.
//

import CoreTransferable
import Foundation
import HFoundation
import OSLog

private let log = Logger(subsystem: "HMedia", category: "HMediaItem")

public enum HMediaType: String, RawRepresentable, Sendable {
  case image
  case gif
  case movie
}

public struct HMediaItem: Transferable, Identifiable, Sendable {
  fileprivate init(data: Data, type: HMediaType, pathExtension: String, tempUrl: URL? = nil) {
    self.data = data
    self.type = type
    self.pathExtension = pathExtension
    self.tempUrl = tempUrl
  }

  public let id = UUID()
  public let data: Data
  public let type: HMediaType
  public let pathExtension: String
  public let tempUrl: URL?
  public var identifier: String?

  public static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(importedContentType: .gif) { gifFile in
      let data = try Data(contentsOf: gifFile.file)
      return Self(data: data, type: .gif, pathExtension: gifFile.file.pathExtension, tempUrl: gifFile.file)
    }
    FileRepresentation(contentType: .image) { item in
      let url = URL.makeTempUrl().appendingPathExtension(item.pathExtension)
      try item.data.write(to: url)
      return SentTransferredFile(url)
    } importing: { imageFile in
      let data = try Data(contentsOf: imageFile.file)
//        log.info("copy image from \(imageFile.file) to \(URL.makeTempUrl()) success")
      return Self(data: data, type: .image, pathExtension: imageFile.file.pathExtension, tempUrl: imageFile.file)
    }
    FileRepresentation(importedContentType: .movie) { videoFile in
//      let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//      let url = documentDirectory.appending(path: "video/\(UUID()).\(videoFile.file.pathExtension)")
//      do {
//        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
//        try FileManager.default.moveItem(at: videoFile.file, to: url)
//      }
//      catch {
//        log.error("copy movie to \(url) failed \(error)")
//      }
      let data = try Data(contentsOf: videoFile.file)
      return Self(data: data, type: .movie, pathExtension: videoFile.file.pathExtension, tempUrl: videoFile.file)
    }
  }
}

#if canImport(UIKit) && DEBUG
  import UIKit

  public extension HMediaItem {
    static func fromJpegImage(_ image: UIImage) -> Self {
      return self.init(data: image.jpegData(compressionQuality: 0.8)!, type: .image, pathExtension: "jpeg")
    }
  }

#endif
