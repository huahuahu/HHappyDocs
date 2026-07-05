//
//  HLocation.swift
//  HSharedCode
//
//  Created by tigerguo on 2024/9/27.
//

import OSLog

let hLocationLog = Logger(subsystem: "com.tiger.hlocation", category: "hlocation")

public struct HLocation: Decodable, Equatable, Hashable {
  public init(
    name: String,
    content: String?,
    latitude: Double,
    longitude: Double
  ) {
    self.name = name
    self.content = content
    self.latitude = latitude
    self.longitude = longitude
  }

  let name: String
  let content: String?
  /// 纬度
  let latitude: Double
  /// 经度
  let longitude: Double
}
