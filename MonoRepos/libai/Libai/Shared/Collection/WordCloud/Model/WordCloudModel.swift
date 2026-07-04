//
//  WordCloudModel.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/22.
//

import Foundation
import WebKit

class WordCloudModel: NSObject, ObservableObject {
  private let jsonEncoder = JSONEncoder()

  @Published var loadFinish = false
  private var pendingWordList: [WordEntry]?
  var isShowingUpdateCallBack: ((Bool) -> Void)?

  lazy var webView: HWebView = {
    let config = WKWebViewConfiguration()
    config.userContentController.add(WeakScriptHandler(self), name: "general")
    config.userContentController.add(WeakScriptHandler(self), name: "log")
    hLog("webview init", scenerio: .wordCloud)
    let webview = HWebView(frame: .zero, configuration: config)
    webview.isOpaque = false
    webview.onColorSchemeChange = { [weak self] in
      self?.setNewColorScheme()
    }
    webview.onSizeChange = { [weak self] in
      self?.triggerNewDraw()
    }
    return webview
  }()

  let html: String = {
    // swiftlint:disable:next force_try
    let url = Bundle.main.url(forResource: "word-cloud", withExtension: "html")!
    // swiftlint:disable:next force_try
    let string = try! String(contentsOf: url)

    return string
  }()

  deinit {
    webView.configuration.userContentController.removeAllScriptMessageHandlers()
  }

  override init() {
    super.init()
    webView.scrollView.isScrollEnabled = false
    if Settings.shared.useDebugUrlForWeb {
      let url = URL(string: "http://localhost:4200")!
      webView.load(URLRequest(url: url))
    }
    else {
      webView.loadHTMLString(html, baseURL: nil)
    }
  }

  func uploadEntry(_ newEntry: [WordEntry]) throws {
    if !loadFinish {
      pendingWordList = newEntry
      return
    }
    pendingWordList = nil
    let data = try jsonEncoder.encode(newEntry)
    guard let parameterString = String(data: data, encoding: .utf8) else {
      fatalError("can't get string")
    }
    let jsMethodName = "window.updateList"
    let jsString = jsMethodName + "(" + parameterString + ")"
    webView.evaluateJavaScript(jsString) { result, error in
      hLog("update list \(jsString), result \(String(describing: result)), error: \(String(describing: error))", scenerio: .wordCloud)
    }
  }

  func setIsUpdating() {
    let jsString = "window.setIsRecalculating()"
    webView.evaluateJavaScript(jsString) { result, error in
      hLog("setIsRecalculating \(jsString), result \(String(describing: result)), error: \(String(describing: error))", scenerio: .wordCloud)
    }
  }

  private func setNewColorScheme() {
    let isDarkMode = webView.traitCollection.userInterfaceStyle == .dark
    let jsString = "window.updateColorScheme(\(isDarkMode))"
    webView.evaluateJavaScript(jsString) { result, error in
      hLog("updateColorScheme \(jsString), result \(String(describing: result)), error: \(String(describing: error))", scenerio: .wordCloud)
    }
  }

  func triggerNewDraw() {
    let jsString = "window.api.triggerNewDraw()"
    webView.evaluateJavaScript(jsString) { result, error in
      hLog("triggerNewDraw \(jsString), result \(String(describing: result)), error: \(String(describing: error))", scenerio: .wordCloud)
    }
  }
}

extension WordCloudModel: WKScriptMessageHandler {
  enum BridgeMessageSubType: String, RawRepresentable {
    case updateLoadReady
    case updateIsShowing
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "general" {
      guard let body = message.body as? [String: Any],
            let subTypeRaw = body["subType"] as? String,
            let subType = BridgeMessageSubType(rawValue: subTypeRaw)
      else {
        hAssertFailure("unknow body")
        return
      }
      switch subType {
      case .updateLoadReady:
        onLoadFinish()
      case .updateIsShowing:
        onIsShowingUpdate(body)
      }
    }
    else if message.name == "log" {
      if let body = message.body as? [String: Any],
         let content = body["content"] as? [String: Any],
         let log = content["log"] as? String {
        hLog("jslog \(log)", scenerio: .wordCloud)
      }
    }
  }

  private func onIsShowingUpdate(_ body: [String: Any]) {
    guard let content = body["content"] as? [String: Any],
          let isShowingPicture = content["isShowingPicture"] as? Bool
    else {
      hAssertFailure("Invalid body \(body)")
      return
    }
    hLog("isShowingPicture -> \(isShowingPicture)", scenerio: .wordCloud)
    isShowingUpdateCallBack?(isShowingPicture)
  }

  private func onLoadFinish() {
    hLog("load finish", scenerio: .wordCloud)

    setNewColorScheme()
    loadFinish = true

    if let pending = pendingWordList {
      try? uploadEntry(pending)
    }
  }
}

extension WordCloudModel {
  func takeScreenshot() -> UIImage? {
    let topImage = webView.makeScreenshot()
    let theme = Theme(webView.traitCollection.userInterfaceStyle)
    let image = topImage.addLogo(theme: theme)
    return image
//    let qrSize = 100.0
//    let targetSize = CGSize(width: topImage.size.width, height: topImage.size.height + qrSize + 10.0)
//    let view = UIView(frame: .init(origin: .zero, size: targetSize))
//    let topImageView = UIImageView(frame: .init(origin: .zero, size: topImage.size))
//    topImageView.image = topImage
//    let buttonImageView = UIImageView(frame: .init(x: 0, y: topImageView.frame.maxY + 10.0, width: qrSize, height: qrSize))
//    let str = "https://apps.apple.com/cn/app/%E6%9D%8E%E7%99%BD/id1609067377?l=en"
//
//    buttonImageView.image = UIImage.generateCode(inputMsg: str, fgImage: nil)
//
//    view.addSubview(topImageView)
//    view.addSubview(buttonImageView)
//
//    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
//    return renderer.image { context in
//      view.layer.render(in: context.cgContext)
//    }
  }
}
