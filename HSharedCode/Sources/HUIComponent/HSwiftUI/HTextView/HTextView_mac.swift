//
//  HTextView_iOS.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//
#if os(macOS)

  import SwiftUI
  import WebKit

  public struct HTextView: NSViewRepresentable, Hashable {
    public init() {}

    public func makeNSView(context: Context) -> NSScrollView {
      let scrollView = NSTextView.scrollableTextView()
      return scrollView
    }

    public func updateNSView(_ uiView: NSScrollView, context: Context) {}
  }

#endif
