//
//  Data+Util.swift
//
//
//  Created by tigerguo on 2024/4/11.
//

import AppleArchive
import Foundation
import OSLog
import System

public enum HCompress {
  static let log = Logger(subsystem: "HData", category: "compress")

  public static func archiveFolder(_ src: URL, to destination: URL) throws {
    log.info("archiving folder \(src) start")

    let archiveFilePath = FilePath(destination.path(percentEncoded: false))
    guard let writeFileStream = ArchiveByteStream.fileStream(
      path: archiveFilePath,
      mode: .writeOnly,
      options: [.create],
      permissions: FilePermissions(rawValue: 0o644)
    ) else {
      return
    }
    defer {
      log.info("closing writeFileStream")
      try? writeFileStream.close()
    }

    guard let compressStream = ArchiveByteStream.compressionStream(
      using: .lzfse,
      writingTo: writeFileStream
    ) else {
      return
    }

    defer {
      log.info("closing compressStream")

      try? compressStream.close()
    }

    guard let encodeStream = ArchiveStream.encodeStream(writingTo: compressStream) else {
      return
    }

    defer {
      log.info("closing encodeStream")

      try? encodeStream.close()
    }

    guard let keySet = ArchiveHeader.FieldKeySet("TYP,PAT,LNK,DEV,DAT,UID,GID,MOD,FLG,MTM,BTM,CTM") else {
      return
    }

    let source = FilePath(src.path(percentEncoded: false))

    try encodeStream.writeDirectoryContents(
      archiveFrom: source,
      keySet: keySet
    )
    Self.log.info("archiving folder \(src) end")
  }
}
