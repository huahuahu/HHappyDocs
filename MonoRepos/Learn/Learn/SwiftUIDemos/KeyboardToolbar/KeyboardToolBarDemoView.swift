//
//  KeyboardToolBarDemoView.swift
//  Learn
//
//  Created by tigerguo on 2025/1/27.
//

import SwiftUI

extension SwiftUIDemo {
  @MainActor struct KeyboardToolBarDemoView: View {
    enum Field: Hashable {
      case upperTextField
      case lowerTextField
    }

    @State private var name = "Taylor"
    @FocusState private var focusedField: Field?

    @State private var showSecondLineButton = false

    @State private var showSheet = false

    var body: some View {
      List {
        Text(name)
          .padding()
          .font(.headline)
      }
      .scrollDismissesKeyboard(.interactively)
      .sheet(isPresented: $showSheet, content: {
        NavigationStack {
          Text(verbatim: "presented view")
        }
        .presentationDetents([.medium, .large])
      })
      .safeAreaInset(edge: .bottom) {
        toolbarView
      }
      .navigationTitle(SwiftUIDemoEntry.keyboardToolbar.title)
//      .toolbar {
//          ToolbarItemGroup(placement: toolbarPlaceMent) {
//            toolbarView
//        }
//      }
    }

    private var toolbarPlaceMent: ToolbarItemPlacement {
      switch focusedField {
      case .upperTextField:
        return .bottomBar
      case .lowerTextField:
        return .bottomBar
      case .none:
        return .bottomBar
      }
    }

    @ViewBuilder
    private var toolbarView: some View {
      VStack {
        TextField(text: $name, prompt: Text(verbatim: "text here"), axis: .vertical) {
          Text(verbatim: "text")
        }
        .lineLimit(4)
        .textFieldStyle(.roundedBorder)
        .focused($focusedField, equals: .lowerTextField)

        HStack {
          Button(action: {
            withAnimation {
              showSecondLineButton.toggle()
            }
          }, label: {
            Image(systemName: "plus.circle")
          })
          .padding()

          Spacer()

          Button(action: {
            showSheet = true
          }, label: {
            Image(systemName: "photo.badge.plus")
          })
          .padding()

          Button(action: {
            focusedField = nil
          }, label: {
            Image(systemName: "folder.badge.plus")
          })
          .padding()
        }
        if showSecondLineButton {
          // Add three card buttons
          HStack {
            Button(action: {}, label: {
              Image(systemName: "plus.circle")
            })
            .padding()
            Button(action: {}, label: {
              Image(systemName: "plus.circle")
            })
            .padding()

            Button(action: {}, label: {
              Image(systemName: "plus.circle")
            })
            .padding()
          }
        }
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    SwiftUIDemo.KeyboardToolBarDemoView()
  }
}
