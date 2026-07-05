//
//  LocalizedString.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/3/19.
//

import Foundation

enum LocalizedString {
  static let empty = String(localized: "empty", bundle: .module, comment: "")
  static let darkTheme = String(localized: "theme.dark", bundle: .module, comment: "setting text for selecting dark theme")
  static let lightTheme = String(localized: "theme.light", bundle: .module, comment: "setting text for selecting light theme")
  static let systemTheme = String(localized: "theme.auto", bundle: .module, comment: "setting text for selecting system theme")
  static let themeSelectorDescription = String(localized: "themeSelectorDescription", bundle: .module, comment: "Description for theme selector")

  static let appearance = String(localized: "appearance", bundle: .module, comment: "Text for triggering theme selection")

  static let unlockToProceed = String(localized: "unlock to proceed", bundle: .module)
  static let localAuthCellText = String(localized: "localAuth.cellText", bundle: .module, comment: "Cell shown along with switch to enable security auth")
  static let localAuthEnableFailureAlertTitle = String(localized: "localAuth.enableFailureAlert.title", bundle: .module, comment: "")

  static let localAuthEnableFailureAlertMessage = String(localized: "localAuth.enableFailureAlert.message", bundle: .module, comment: "")

  static func unlock(appName: String) -> String {
    return String(localized: "unlock \(appName)", bundle: .module, comment: "Unlock app")
  }

  static let feedbackCellText = String(localized: "feedback.cellText", bundle: .module, comment: "")

  static func feedback(for appName: String) -> String {
    return String(localized: "feedback.subject of \(appName)", bundle: .module, comment: "Feedback email subject")
  }

  static let feedbackErrorMessage = String(localized: "feedback.errorMessage", bundle: .module, comment: "")
  static let feedbackErrorTitle = String(localized: "feedback.errorTitle", bundle: .module, comment: "")

  static let version = String(localized: "version", bundle: .module, comment: "")
}

enum HUIComponentString {
  public static let crop = LocalizedStringResource("crop", table: "Localizable", comment: "title used to crop image")
  enum SelectionView {
    public static let add = LocalizedStringResource("add", table: "Localizable", comment: "context menu label to add item")
    public static let remove = LocalizedStringResource("remove", table: "Localizable", comment: "context menu label to remove item")
  }
}

extension LocalizedStringResource {
  func hDocLocalized() -> String {
    String(localized: .init(stringLiteral: self.key), bundle: .module)
  }
}
