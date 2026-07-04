//
//  DateInfo.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/22.
//

import Foundation

struct ExifDateInfo: Equatable, Hashable {
  let date: Date
  let timeZone: TimeZone

  func hash(into hasher: inout Hasher) {
    hasher.combine(date)
    hasher.combine(timeZone)
  }
}

extension DateFormatter {
  static let exifDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss XXXXX"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
}
