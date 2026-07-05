//
//  ConditionalModifier.swift
//  HSharedCode
//
//  Created by tigerguo on 2025/3/26.
//

import SwiftUI

public extension View {
  @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content)
    -> some View {
    if condition {
      transform(self)
    }
    else {
      self
    }
  }
}
