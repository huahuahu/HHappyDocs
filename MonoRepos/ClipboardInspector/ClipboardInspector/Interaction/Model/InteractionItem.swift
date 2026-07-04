//
//  InteractionItem.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation

enum InteractionItem: CaseIterable, Identifiable {
  case uikitTextView
  case uikitTextField
  case webview
  #if os(iOS) || os(visionOS)
    case clear
  #endif

  var text: String {
    switch self {
    case .uikitTextView:
      return "UITextView"
    case .uikitTextField:
      return "UITextField"
    case .webview:
      return "WKWebView"
    #if os(iOS) || os(visionOS)
      case .clear:
        return LocalizedString.clearPasteboardAction
    #endif
    }
  }

  var id: String {
    text
  }
}
