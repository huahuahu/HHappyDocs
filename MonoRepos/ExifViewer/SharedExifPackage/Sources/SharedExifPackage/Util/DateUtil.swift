//
//  DateUtil.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/22.
//
import Foundation

enum DateUtil {
  // TimeZone string example: "+08:00"
  static func timeZone(from timeZoneString: String) -> TimeZone? {
    // 提取小时和分钟
    let pattern = "^([+-])(\\d{2}):(\\d{2})$"
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: timeZoneString, range: NSRange(timeZoneString.startIndex..., in: timeZoneString)) else {
      return nil
    }

    // 提取符号、小时、分钟
    let signRange = Range(match.range(at: 1), in: timeZoneString)!
    let hourRange = Range(match.range(at: 2), in: timeZoneString)!
    let minuteRange = Range(match.range(at: 3), in: timeZoneString)!

    let sign = String(timeZoneString[signRange]) == "+" ? 1 : -1
    let hours = Int(String(timeZoneString[hourRange])) ?? 0
    let minutes = Int(String(timeZoneString[minuteRange])) ?? 0

    let totalSeconds = sign * (hours * 3600 + minutes * 60)
    return TimeZone(secondsFromGMT: totalSeconds)
  }
}
