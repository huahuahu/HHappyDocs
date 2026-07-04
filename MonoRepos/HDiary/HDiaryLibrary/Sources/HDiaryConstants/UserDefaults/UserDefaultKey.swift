//
//  UserDefaultKey.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation

enum UserDefaultKey: String, CaseIterable {
  case theme
  case appLockEnabled
  case hasShownRecordPromotionView
  case recordSubscriptionStatus

  // MARK: - Debug start

  case swiftDataContainerType
  case supportSearch
  case bypassIPRestriction

  // MARK: - Debug end
}

public enum SwiftDataContainerType: Int, Identifiable, CaseIterable {
  case iCloud
  case local
  case inMemory

  public var id: Int {
    rawValue
  }
}
