//
//  HNavigationbarTitleDisplayMode.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/19.
//

import Foundation
import SwiftUI

public enum HNavigationBarItem {
  public enum TitleDisplayMode {
    case automatic
    case inline
    case large
  }
}

#if os(iOS)
  fileprivate extension NavigationBarItem.TitleDisplayMode {
    init(_ mode: HNavigationBarItem.TitleDisplayMode) {
      switch mode {
      case .automatic:
        self = .automatic
      case .inline:
        self = .inline
      case .large:
        self = .large
      }
    }
  }
#endif

public extension View {
  func hNavigationBarTitleDisplayMode(_ mode: HNavigationBarItem.TitleDisplayMode) -> some View {
    #if os(iOS)
      self.navigationBarTitleDisplayMode(.init(mode))
    #else
      self
    #endif
  }
}
