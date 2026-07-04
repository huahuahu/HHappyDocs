//
//  HWebView.swift
//  Libai
//
//  Created by huahuahu on 2022/4/24.
//

import Foundation
import WebKit

class HWebView: WKWebView {
  let trackingID = UUID()

  var onColorSchemeChange: (() -> Void)?

  var onSizeChange: (() -> Void)?

  var oldSize: CGSize?

  override init(frame: CGRect, configuration: WKWebViewConfiguration) {
    super.init(frame: frame, configuration: configuration)
    hLog("\(trackingID.uuidString) init", scenerio: .default)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    hLog("\(trackingID.uuidString) deinit", scenerio: .default)
  }

  #if os(iOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
        onColorSchemeChange?()
      }

      if (previousTraitCollection?.verticalSizeClass, previousTraitCollection?.horizontalSizeClass) != (traitCollection.verticalSizeClass, traitCollection.horizontalSizeClass) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          self.onSizeChange?()
        }
      }
    }
  #endif
}
