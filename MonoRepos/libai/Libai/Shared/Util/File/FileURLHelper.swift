//
//  FileURLHelper.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/16.
//

import Foundation

enum FileURLHelper {
  static func getTempUrl() -> URL {
    let tempUrl = FileManager.default.temporaryDirectory
    return tempUrl
  }

  static func tempUrlAfter(writing data: Data) throws -> URL {
    let tempUrl = getTempUrl().appendingPathComponent(UUID().uuidString)
    try data.write(to: tempUrl, options: .atomic)
    return tempUrl
  }
}
