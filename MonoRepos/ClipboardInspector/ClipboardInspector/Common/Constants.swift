//
//  Constants.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/18.
//

import Foundation
import HUIComponent

enum AppConstants {
  static let localAuthConfig = LocalAuthConfig(
    touchIDReason: LocalizedString.permissionForLocalAuthReason,
    appName: LocalizedString.appName
  )
}
