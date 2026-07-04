//
//  HLocalizedString.swift
//  HLocalization
//
//  Created by tigerguo on 2023/3/19.
//

import Foundation

public enum HLocalizedString {
  public static let trueDescription = String(localized: "bool.true", bundle: .module, comment: "")
  public static let falseDescription = String(localized: "bool.false", bundle: .module, comment: "")

  public static let nothing = String(localized: "nothing", bundle: .module, comment: "")
  public static let setting = String(localized: "settings", bundle: .module, comment: "Used for settings")
  public static let ok = String(localized: "OK", bundle: .module, comment: "")
  public static let reset = String(localized: "Reset", bundle: .module, comment: "")
  public static let confirm = String(localized: "Confirm", bundle: .module, comment: "")
  public static let dismiss = String(localized: "Dismiss", bundle: .module, comment: "")
}
