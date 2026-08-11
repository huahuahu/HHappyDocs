//
//  UserDefaultKey.swift
//  HDiaryConstants
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation

enum UserDefaultKey: String, CaseIterable {
  case theme
  case appLockEnabled
  case hasShownRecordPromotionView
  case recordSubscriptionStatus

  // MARK: - Diagnostic logging

  // 显式保留原始字符串，避免调整代码结构后丢失已经持久化的诊断状态。
  case diagnosticLoggingIsEnabled = "diagnosticLogging.isEnabled"
  case diagnosticLoggingStartedAtMilliseconds = "diagnosticLogging.startedAtMilliseconds"

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
