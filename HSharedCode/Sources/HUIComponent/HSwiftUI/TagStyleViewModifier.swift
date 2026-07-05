//
//  TagStyleViewModifier.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/20.
//

import Foundation
import SwiftUI

public struct TagStyleViewModifier: ViewModifier {
  @ScaledMetric private var verticalPadding = 5.0
  @ScaledMetric private var horizontalPadding = 15.0
  @ScaledMetric private var cornerRadius = 30.0

  public enum State {
    case selected
    case notSelected
  }

  let state: Self.State

  public func body(content: Content) -> some View {
    content
      .padding(.vertical, verticalPadding)
      .padding(.horizontal, horizontalPadding)
      .background(backgroundColor)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(borderColor, lineWidth: 1)
      )
  }

  private var backgroundColor: Color {
    return state == .selected ? .accentColor.opacity(0.2) : .gray.opacity(0.2)
  }

  private var borderColor: Color {
    return state == .selected ? Color.accentColor : .clear
  }
}

// 在视图扩展中使用自定义的 View Modifier
public extension View {
  func tagStyle(_ state: TagStyleViewModifier.State) -> some View {
    self.modifier(TagStyleViewModifier(state: state))
  }
}

#Preview("tags") {
  VStack {
    Text(verbatim: "sport")

      .tagStyle(.notSelected)
    Divider()
    Text(verbatim: "sport")
      .tagStyle(.selected)
  }
//    .tint(Color.red)

//    .environment(\, <#T##V#>)
}
