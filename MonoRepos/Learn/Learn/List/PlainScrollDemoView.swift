//
//  PlainScrollDemoView.swift
//  Learn
//
//  Created by tigerguo on 2023/12/22.
//

import SwiftUI

struct PlainScrollDemoView: View {
  @State private var scrollPosition: Int?
  var body: some View {
    VStack {
      Button("Jump to #50") {
        scrollPosition = 50
      }
      .buttonStyle(.bordered)
//      .buttonStyle()

      Button("Jump to #150") {
        scrollPosition = 150
      }
      .buttonStyle(.borderedProminent)

      ScrollView {
        LazyVStack(content: {
          ForEach(1 ... 100, id: \.self) { count in
            Text("Example \(count)")
              .id(count)
          }
        })
        .scrollTargetLayout()
        Text(verbatim: "150")
          .id(150)
      }
      .scrollPosition(id: $scrollPosition, anchor: .center)
    }
    .navigationTitle("Plain scroll view")
  }
}

#Preview {
  PlainScrollDemoView()
}
