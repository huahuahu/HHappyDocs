//
//  HDocUserDefauts.swift
//
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation

public extension UserDefaults {
  static let hDocShared = UserDefaults(suiteName: AppConstants.groupName)
}

public enum UserDefaultKey: String, CaseIterable {
  case theme
  case appLockEnabled
  case hasPromotedRecordSubscription
  case recordSubscriptionStatus
}
