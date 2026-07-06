//
//  Locale+util.swift
//  HFoundation
//
//  Created by tigerguo on 2023/4/23.
//

import Foundation

public extension Locale {
  static let en = Locale(identifier: "en")

  static var cnMainland: Locale {
    let dd = Locale(identifier: "zh_CN")
    return dd
  }

  static let cnHK = Locale(identifier: "zh_HK")

  static let cnTaiwan = Locale(identifier: "zh_TW")
}
