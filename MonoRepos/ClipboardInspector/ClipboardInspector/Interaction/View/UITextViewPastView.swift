//
//  UITextViewPastView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import HUIComponent
import SwiftUI

struct UITextViewPastView: View {
  enum Field {
    case text
  }

  @FocusState private var field: Field?
  var body: some View {
    VStack {
      HTextView()
        .border(.gray)
        .padding()
        .focused($field, equals: .text)
    }
    .onAppear {
      field = .text
    }
  }
}

struct UITextViewPastView_Previews: PreviewProvider {
  static var previews: some View {
    UITextViewPastView()
  }
}
