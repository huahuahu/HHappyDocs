//
//  WebPasteView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import HUIComponent
import SwiftUI

// swiftlint:disable:next force_unwrapping
private let kHtmlUrl = Bundle.main.url(forResource: "paste", withExtension: "html")!

struct WebPasteView: View {
  enum Field {
    case text
  }

  @FocusState private var field: Field?

  var body: some View {
    HWebView(url: kHtmlUrl)
      .focused($field, equals: .text)
      .onAppear {
        field = .text
      }
  }
}

struct WebPasteView_Previews: PreviewProvider {
  static var previews: some View {
    WebPasteView()
  }
}
