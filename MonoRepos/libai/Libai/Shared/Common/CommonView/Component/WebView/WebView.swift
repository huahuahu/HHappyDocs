//
//  WebView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/22.
//

import Foundation
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  let webview: WKWebView

  func updateUIView(_: UIViewType, context _: Context) {}

  func makeUIView(context _: Context) -> WKWebView {
    webview
  }
}
