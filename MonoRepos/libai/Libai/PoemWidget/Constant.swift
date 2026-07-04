//
//  Constant.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/8.
//

import Foundation

enum HWidgetKind: String {
  case poems

  var title: String {
    switch self {
    case .poems:
      return "诗词"
    }
  }

  var kind: String {
    switch self {
    case .poems:
      return "PoemWidget"
    }
  }
}
