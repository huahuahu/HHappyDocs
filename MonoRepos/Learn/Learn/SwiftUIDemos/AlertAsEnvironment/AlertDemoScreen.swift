//
//  AlertDemoScreen.swift
//  Learn
//
//  Created by tigerguo on 2025/3/23.
//

import SwiftUI

extension SwiftUIDemo {
  @MainActor
  struct AlertDemoScreen: View {
    @Environment(\.showAlert) private var showAlert
    @State private var isPresented = false

    var body: some View {
      List {
        Button("Show Alert") {
          showAlert("Title", "Message")
        }

        Button("present new view") {
          isPresented = true
        }
      }
      .sheet(isPresented: $isPresented, content: {
        presentedView
      })
    }

    @ViewBuilder
    private var presentedView: some View {
      Self()
        .withAlert()
    }
  }
}

// private extension SwiftUIDemo {
//    @MainActor
//    struct InnerView: View {
//        @Environment(\.showAlert) private var showAlert
//        var body: some View {
//            List {
//                Button("Show Alert") {
//                    showAlert("Title", "Message")
//                }
//
//                Button("present new view") {
//                    print("present new view")
//                }
//            }
//
//        }
//    }
// }

#Preview { @MainActor in
  NavigationStack {
    SwiftUIDemo.AlertDemoScreen()
  }
}
