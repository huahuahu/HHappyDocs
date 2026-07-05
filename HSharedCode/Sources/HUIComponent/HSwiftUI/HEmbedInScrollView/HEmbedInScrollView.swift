//
//  HEmbedInScrollView.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/18.
//

import Foundation
import SwiftUI

struct HEmbedInScrollView: ViewModifier {
  func body(content: Content) -> some View {
    GeometryReader { geometry in
      ScrollView {
        content
          .frame(width: geometry.size.width) // Make the scroll view full-width
          .frame(minHeight: geometry.size.height) // Set the content’s min height to the parent
      }
    }
  }
}

public extension View {
  func embedInScrollView() -> some View {
    modifier(HEmbedInScrollView())
  }
}
