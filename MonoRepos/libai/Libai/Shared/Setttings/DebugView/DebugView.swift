//
//  DebugView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/12.
//

import SwiftUI
import WebKit

struct DebugView: View {
  @StateObject var model = WebViewModel()
//  var indexView: some View {
//    IndexView(containerHeight: .constant(100), indexItems:
//      .constant([
//        IndexItem(displayText: "a", onTap: {}),
//        IndexItem(displayText: "b", onTap: {}),
//        IndexItem(displayText: "c", onTap: {}),
//      ]))
//  }

  var body: some View {
    WebView(webview: model.webView)
      .border(.red, width: 1)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("update") {
            model.refresh()
          }
        }
      }
  }
}

struct DebugView_Previews: PreviewProvider {
  static var previews: some View {
    DebugView()
  }
}

class WebViewModel: ObservableObject {
  func refresh() {
    let jsString = "window.update()"
    webView.evaluateJavaScript(jsString) { _, _ in
//      hLog("js \(result), \(error)")
    }
  }

  let webView: WKWebView
  let html: String = {
    // swiftlint:disable force_try
    let url = Bundle.main.url(forResource: "wordCloud", withExtension: "html")!
    let string = try! String(contentsOf: url)
    // swiftlint:enable force_try
    return string
  }()

  init() {
    webView = WKWebView(frame: .zero)

    loadUrl()
  }

  func loadUrl() {
    webView.loadHTMLString(html, baseURL: nil)
  }
}
