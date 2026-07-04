//
//  CreativeWork.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import Foundation
import SwiftUI

enum CreativeWorkType: CaseIterable, Identifiable {
  case poems
  case prose
  case calligraphy

  var title: String {
    switch self {
    case .poems:
      return "诗歌"
    case .prose:
      return "散文"
    case .calligraphy:
      return "书法"
    }
  }

  var id: String { title }
}
