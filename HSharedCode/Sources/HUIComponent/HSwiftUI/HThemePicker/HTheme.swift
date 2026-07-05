//
//  HTheme.swift
//  HFoundation
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation

public enum HTheme: Int, RawRepresentable, CaseIterable, Identifiable {
  case auto = 0
  case dark
  case light

  public var id: Int {
    rawValue
  }

  var settingText: String {
    switch self {
    case .auto:
      return LocalizedString.systemTheme
    case .dark:
      return LocalizedString.darkTheme
    case .light:
      return LocalizedString.lightTheme
    }
  }

//  init(_ userInterface: UIUserInterfaceStyle) {
//    switch userInterface {
//    case .unspecified:
//      self = .auto
//    case .light:
//      self = .light
//    case .dark:
//      self = .dark
//    @unknown default:
//      self = .auto
//    }
//  }
}

// extension UIUserInterfaceStyle {
//  init(_ theme: HTheme) {
//    switch theme {
//    case .auto:
//      self = .unspecified
//    case .dark:
//      self = .dark
//    case .light:
//      self = .light
//    }
//  }
// }
