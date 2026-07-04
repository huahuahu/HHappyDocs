//
//  ThemeModifier.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/5.
//

import Foundation
import SwiftUI

struct ThemeModify: ViewModifier {
  let theme: Theme?
  func body(content: Content) -> some View {
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

extension View {
  func theme(_ theme: Theme?) -> some View {
    modifier(ThemeModify(theme: theme))
  }
}
