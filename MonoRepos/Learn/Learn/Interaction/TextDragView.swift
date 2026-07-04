//
//  TextDragView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/14.
//

import SwiftUI

@MainActor
struct TextDragView: View {
  @State var text: String = ""
  var body: some View {
    ScrollView {
      TextEditor(text: $text)
        .border(.gray)
        .padding()
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
        .containerRelativeFrame([.horizontal, .vertical])
    }
  }
}

#Preview {
  TextDragView()
}
