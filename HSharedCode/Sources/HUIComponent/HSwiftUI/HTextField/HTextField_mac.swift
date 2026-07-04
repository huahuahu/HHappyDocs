//
//  HTextField_iOS.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//
#if os(macOS)

  import SwiftUI
  import WebKit

  /// Bridged from UITextField
  public struct HTextField: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSTextField {
      let textView = NSTextField()
//      textView.layer.borderColor = UIColor.gray.cgColor
//      textView.layer.borderWidth = 0.5
      return textView
    }

    public func updateNSView(_ nsView: NSTextField, context: Context) {}
  }

#endif
