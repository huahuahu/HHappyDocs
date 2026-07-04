//
//  HWebView_mac.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//

#if os(macOS)
  import SwiftUI
  import WebKit

  public struct HWebView: NSViewRepresentable {
    public init(url: URL) {
      self.url = url
    }

    public let url: URL

    public func makeNSView(context: Context) -> WKWebView {
      let webView = WKWebView()
      webView.navigationDelegate = context.coordinator
      return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
      let request = URLRequest(url: url)
      nsView.load(request)
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
