//
//  LocationOpener.swift
//  HSharedCode
//
//  Created by tigerguo on 2024/9/27.
//

import Foundation

// enum HLocationOpener {
//  case amap
//  case baidu
//
//  var locationOpening: HLocationOpening {
//    switch self {
//    case .amap:
//      return AMapOpener()
//    case .baidu:
//      return BaiduMapOpener()
//    }
//  }
//
//  static let appNameForLocation = "ios.tigerhuahuahu.hdiary"
// }

public protocol HLocationOpener {
  func open(_ location: HLocation)
}
