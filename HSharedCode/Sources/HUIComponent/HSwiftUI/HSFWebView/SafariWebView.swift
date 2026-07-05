//
//  SafariWebView.swift
//
//
//  Created by tigerguo on 2024/2/7.
//
#if os(iOS)

  import SafariServices
  import SwiftUI

  @MainActor
  public struct HSafariWebView: UIViewControllerRepresentable {
    public init(
      url: URL,
      entersReaderIfAvailable: Bool? = nil,
      tintColor: UIColor? = nil
    ) {
      self.url = url
      self.entersReaderIfAvailable = entersReaderIfAvailable
      self.tintColor = tintColor
    }

    let url: URL
    let entersReaderIfAvailable: Bool?
    let tintColor: UIColor?

    public func makeUIViewController(context: Context) -> SFSafariViewController {
      let configuration = SFSafariViewController.Configuration()
      if let entersReaderIfAvailable {
        configuration.entersReaderIfAvailable = entersReaderIfAvailable
      }

      let safari = SFSafariViewController(url: url, configuration: configuration)
      if let tintColor {
        #if os(visionOS)
        #else
          safari.preferredControlTintColor = tintColor
        #endif
      }

      return safari
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
  }

  #Preview { @MainActor in
    HSafariWebView(url: URL(string: "https://apple.com")!)
  }

#endif
