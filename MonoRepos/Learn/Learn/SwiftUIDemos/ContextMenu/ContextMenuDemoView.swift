//
//  ContextMenuDemoView.swift
//  Learn
//
//  Created by tigerguo on 2024/11/28.
//

import SwiftUI

extension SwiftUIDemo {
  @MainActor
  struct ContextMenuDemoView: View {
    var body: some View {
      VStack {
        Text("Context Menu Demo")
          .font(.largeTitle)
          .padding()

        Text("Long press on the box below to see the context menu.")
          .padding()

        Button(action: {
          Log.common.info("button tapped")
        }, label: {
          Text(verbatim: "tap me")
        })
        .buttonStyle(.borderedProminent)
        .contextMenu {
          Button(action: {
            // Action for first menu item
            Log.common.info("first action")
          }) {
            Text("First Action")
            Image(systemName: "1.circle")
          }

          Button(action: {
            // Action for second menu item
          }) {
            Text("Second Action")
            Image(systemName: "2.circle")
          }

          Button(action: {
            // Action for third menu item
          }) {
            Text("Third Action")
            Image(systemName: "3.circle")
          }
        } preview: {
          contextPreview
        }
      }
      .navigationTitle("Context Menu Demo")
      .navigationBarTitleDisplayMode(.inline)
    }

    private var contextPreview: some View {
      VStack {
        Text("Previewa")
        Text(verbatim: "long long long string sttring string this example, the TextEditor view is used to create an editable multiline text field. The @State property wrapper is used to bind the text content, and the padding() and border() ")
          .lineLimit(nil)
          .truncationMode(.head)
      }

      .frame(idealWidth: 300)
      .padding()
    }
  }
}

#Preview {
  SwiftUIDemo.ContextMenuDemoView()
}
