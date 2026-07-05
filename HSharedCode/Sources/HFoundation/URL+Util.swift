//
//  URL+Util.swift
//  HFoundation
//
//  Created by tigerguo on 2023/3/26.
//

import Foundation

public extension URL {
  static func makeTempUrl() -> URL {
    let tempDirURL = NSURL.fileURL(withPath: NSTemporaryDirectory())
    let uniqueFileName = NSUUID().uuidString
    let tempFileURL = tempDirURL.appendingPathComponent(uniqueFileName)
    return tempFileURL
  }
}
