//
//  ListScrollDemoView.swift
//  Learn
//
//  Created by tigerguo on 2023/12/21.
//

import SwiftUI

struct ListScrollDemoView: View {
  @State private var scrollTarget: Int?
  @State private var text: String = "text "
  enum FocusTarget: Hashable {
    case textView
    case button
  }

  @FocusState private var focustarget: FocusTarget?

  @State private var isPresenting = false
  var body: some View {
    ScrollViewReader { proxy in
      VStack {
        Button("Jump to #50") {
          proxy.scrollTo(50, anchor: .top)
        }
        Text(verbatim: "focus target: \(String(describing: focustarget))")

        Form {
          TextField("text field", text: $text)
            .focused($focustarget, equals: .textView)
          Section("can present") {
            Button(action: {
              focustarget = .button
              print("focus tareget change to button")
              // If we don't change focus to button, the scrollview would scroll to the textfield
              isPresenting = true
            }, label: {
              Text(verbatim: "tap to present")
            })
            .focusable()
            .focused($focustarget, equals: .button)
            .sheet(isPresented: $isPresenting, onDismiss: {
              Task {
//                try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
                print("scroll")
                await MainActor.run {
                  proxy.scrollTo(25, anchor: .top)
                }
              }
            }, content: {
              Text(verbatim: "Presented")
            })
          }
          Section("list") {
            ForEach(0 ..< 100, id: \.self) { i in

              Text("Example \(i)")
                .id(i)
            }
          }
        }
      }
      .navigationTitle("Scroll in List")
    }
  }
}

#Preview {
  ListScrollDemoView()
}
