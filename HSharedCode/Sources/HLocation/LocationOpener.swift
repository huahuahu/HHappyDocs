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
//  static let apppNameForLocation = "ios.tigerhuahuahu.libai"
// }

public protocol HLocationOpener {
  func open(_ location: HLocation)
}
