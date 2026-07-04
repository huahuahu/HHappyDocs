//
//  HTextView_iOS.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//

#if os(iOS) || os(visionOS)
  import SwiftUI
  import WebKit

  public struct HTextView: UIViewRepresentable, Hashable {
    public init() {}

    public func makeUIView(context: Context) -> UITextView {
      let textView = UITextView()
//      textView.layer.borderColor = UIColor.gray.cgColor
//      textView.layer.borderWidth = 0.5
      return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {}
  }

#endif
