//
//  InteractionWrapperView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import SwiftUI

struct InteractionWrapperView: View {
  let item: InteractionItem

  @ViewBuilder
  private var content: some View {
    switch item {
    case .uikitTextView:
      UITextViewPastView()
    case .uikitTextField:
      UITextFieldPasteView()
    case .webview:
      WebPasteView()
    #if os(iOS) || os(visionOS)
      case .clear:
        PasteBoardClearView(noPermissionInfo: HPasteboard.shared.getNoPermissionInfo())
    #endif
    }
  }

  var body: some View {
    content
    #if os(iOS) || os(visionOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .navigationTitle(item.text)
  }
}

struct InteractionWrapperView_Previews: PreviewProvider {
  static var previews: some View {
    InteractionWrapperView(item: .uikitTextView)
  }
}
