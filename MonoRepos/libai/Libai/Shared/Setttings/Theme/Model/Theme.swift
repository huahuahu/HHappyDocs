//
//  Theme.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import Foundation
import UIKit

enum Theme: Int, RawRepresentable, CaseIterable, Identifiable {
  case auto = 0
  case dark
  case light

  var id: Int {
    rawValue
  }

  var settingText: String {
    switch self {
    case .auto:
      return "跟随系统"
    case .dark:
      return "深色"
    case .light:
      return "浅色"
    }
  }

  init(_ userInterface: UIUserInterfaceStyle) {
    switch userInterface {
    case .unspecified:
      self = .auto
    case .light:
      self = .light
    case .dark:
      self = .dark
    @unknown default:
      self = .auto
    }
  }
}

extension UIUserInterfaceStyle {
  init(_ theme: Theme) {
    switch theme {
    case .auto:
      self = .unspecified
    case .dark:
      self = .dark
    case .light:
      self = .light
    }
  }
}
