//
//  HTextField_iOS.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//

#if os(iOS) || os(visionOS)
  import SwiftUI
  import WebKit

  /// Bridged from UITextField
  public struct HTextField: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> UITextField {
      let textView = UITextField()
//      textView.layer.borderColor = UIColor.gray.cgColor
//      textView.layer.borderWidth = 0.5
      return textView
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {}
  }
#endif
