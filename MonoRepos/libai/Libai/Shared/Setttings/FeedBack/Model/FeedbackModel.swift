//
//  FeedbackModel.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/7.
//

import Foundation
import HFoundation
#if os(iOS)
  import UIKit
#endif

struct FeedbackModel: Encodable {
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss:SSSSZZZ"
    return formatter
  }()

  init(content: String) {
    self.content = content
  }

  let content: String
  let time = dateFormatter.string(from: Date())
  let version = HAppInfo.getAppVersion() ?? "0"

  #if os(iOS)
    let model = UIDevice().type.rawValue
  #elseif os(macOS)
    let model = "mac"
  #endif
}
