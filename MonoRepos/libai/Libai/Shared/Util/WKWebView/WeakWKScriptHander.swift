//
//  WeakWKScriptHander.swift
//  Libai
//
//  Created by huahuahu on 2022/4/24.
//

import Foundation
import WebKit

final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    delegate?.userContentController(userContentController, didReceive: message)
  }

  private weak var delegate: WKScriptMessageHandler?

  init(_ delegate: WKScriptMessageHandler) {
    self.delegate = delegate
  }
}
