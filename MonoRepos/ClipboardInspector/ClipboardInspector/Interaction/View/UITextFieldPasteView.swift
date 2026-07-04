//
//  UITextFieldPasteView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import HUIComponent
import SwiftUI

struct UITextFieldPasteView: View {
  enum Field {
    case text
  }

  @FocusState private var field: Field?
  var body: some View {
    GeometryReader { geometryProxy in
      ScrollView(.horizontal, showsIndicators: true) {
        HTextField()
          .border(.gray)
          .padding()
          .focused($field, equals: .text)
          .frame(minWidth: geometryProxy.size.width)
      }
    }

    .onAppear {
      field = .text
    }
  }
}

struct UITextFieldPasteView_Previews: PreviewProvider {
  static var previews: some View {
    UITextFieldPasteView()
  }
}
