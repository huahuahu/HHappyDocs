//
//  ThemeModifier.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation
import SwiftUI

public struct ThemeModify: ViewModifier {
  let theme: HTheme?
  public func body(content: Content) -> some View {
    let colorScheme: ColorScheme? = {
      switch theme {
      case .auto, .none:
        return nil
      case .light:
        return .light
      case .dark:
        return .dark
      }
    }()
    return content.preferredColorScheme(colorScheme)
  }
}

public extension View {
  func theme(_ theme: HTheme?) -> some View {
    modifier(ThemeModify(theme: theme))
  }
}
