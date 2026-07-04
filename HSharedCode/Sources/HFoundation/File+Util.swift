//
//  File+Util.swift
//
//
//  Created by tigerguo on 2024/5/25.
//

import Foundation

public enum HFileUtil {
  public static func folderSize(atPath path: String) -> UInt64? {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) else {
      return nil
    }

    var totalSize: UInt64 = 0

    for case let fileURL as URL in enumerator {
      do {
        let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        if fileAttributes.isRegularFile ?? false {
          totalSize += UInt64(fileAttributes.fileSize ?? 0)
        }
      }
      catch {
        print("Error getting file attributes for \(fileURL.path): \(error.localizedDescription)")
      }
    }

    return totalSize
  }
}
