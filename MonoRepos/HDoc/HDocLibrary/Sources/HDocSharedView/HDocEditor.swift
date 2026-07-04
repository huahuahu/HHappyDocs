//
//  HDocEditor.swift
//
//
//  Created by tigerguo on 2024/1/4.
//

import SwiftUI

public struct HDocEditView: View {
  private enum FocusTarget: Equatable {
    case editor
  }

  public init(text: Binding<String>) {
    _text = text
  }

  @ScaledMetric private var cornerRadius = 5.0
  @FocusState private var focusTarget: FocusTarget?
  @Binding var text: String
  public var body: some View {
    TextEditor(text: $text)
      .focused($focusTarget, equals: .editor)
      .scrollIndicators(.hidden)
      .multilineTextAlignment(.leading)
      .cornerRadius(cornerRadius)
      .overlay(RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(Color.accentColor))
      .padding()
      .onAppear {
        focusTarget = .editor
      }
  }
}

private struct PreviewContainerView: View {
  @State private var text = ""
  var body: some View {
    HDocEditView(text: $text)
  }
}

#Preview {
  NavigationStack {
    PreviewContainerView()
  }
}
