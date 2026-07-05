//
//  HFeedback.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/22.
//

import Foundation
#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import Cocoa
#endif
import HFoundation

public struct HFeedbackModel {
  public init(appName: String, version: String? = nil) {
    self.appName = appName
    self.version = version ?? (HAppInfo.getAppVersion() ?? "0.0")
  }

  let emailAddress: String = "huahuahuapple@outlook.com"

  let appName: String
  let version: String

  func getFeedbackUrl() -> URL {
    var urlComponent = URLComponents()
    urlComponent.scheme = "mailto"
    urlComponent.path = emailAddress
    urlComponent.queryItems = [
      URLQueryItem(name: "subject", value: LocalizedString.feedback(for: "\(appName)_V\(version)")),
    ]
    return urlComponent.url!
  }

  @MainActor
  func openFeedbackURL() async -> Bool {
    let url = getFeedbackUrl()
    #if os(iOS) || os(visionOS)
      if UIApplication.shared.canOpenURL(url) {
        let openSuccess = await UIApplication.shared.open(url)
        return openSuccess
      }
      else {
        return false
      }

    #elseif os(macOS)
      return await withCheckedContinuation { continuation in
        NSWorkspace.shared.open(url, configuration: .init(), completionHandler: { _, error in
          if error != nil {
            continuation.resume(returning: false)
          }
          else {
            continuation.resume(returning: true)
          }
        })
      }
    #endif
  }
}

extension HFeedbackModel {
  static let demo = HFeedbackModel(appName: "测试app", version: "1.0")
}
