//
//  UserDefaultKey.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/20.
//

import Foundation

enum UserDefaultKey {
  static let theme = "20220221_03"
  static let useDebugUrlForWeb = "20220424_01"
  static let selectedTab = "20220907_01"
}

extension UserDefaults {
  func reset() {
    for key in dictionaryRepresentation().keys {
      removeObject(forKey: key)
    }
  }
}
