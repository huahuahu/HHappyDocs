//
//  HWebView_ios.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//

#if os(iOS) || os(visionOS)
  import SwiftUI
  import WebKit

  public struct HWebView: UIViewRepresentable {
    public init(url: URL) {
      self.url = url
    }

    public let url: URL

    public func makeUIView(context: Context) -> WKWebView {
      let webView = WKWebView()
      webView.isOpaque = false
      webView.navigationDelegate = context.coordinator
      return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
      let request = URLRequest(url: url)

      uiView.load(request)
    }

    public func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
      let parent: HWebView

      init(_ parent: HWebView) {
        self.parent = parent
      }

      public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Web view started loading the content
      }

      public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Web view finished loading the content
      }
    }
  }

  struct ContentView: View {
    var body: some View {
      HWebView(url: URL(string: "https://clipboardinspector.online")!)
    }
  }
#endif
