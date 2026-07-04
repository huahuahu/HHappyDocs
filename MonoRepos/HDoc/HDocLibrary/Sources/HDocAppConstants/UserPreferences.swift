//
//  UserPreferences.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation
import Observation
import SwiftUI

@MainActor @Observable
public final class UserPreferences {
  public class Storage {
    @AppStorage(UserDefaultKey.theme.rawValue, store: .hDocShared) public var theme: HDocTheme = .auto
    @AppStorage(UserDefaultKey.appLockEnabled.rawValue, store: .hDocShared) public var appLockEnabled = false
    @AppStorage(UserDefaultKey.hasPromotedRecordSubscription.rawValue, store: .hDocShared) public var hasPromotedRecordSubscription = false
    @AppStorage(UserDefaultKey.recordSubscriptionStatus.rawValue, store: .hDocShared) public var recordSubscriptionStatusData: Data?
  }

  public let storage = Storage()
  public static let shared = UserPreferences()

  private init() {
    self.theme = storage.theme
    self.appLockEnabled = storage.appLockEnabled
    self.hasPromotedRecordSubscription = storage.hasPromotedRecordSubscription
    self.recordSubscriptionStatusData = storage.recordSubscriptionStatusData
  }

  public var theme: HDocTheme {
    didSet {
      storage.theme = theme
    }
  }

  public var appLockEnabled: Bool {
    didSet {
      storage.appLockEnabled = appLockEnabled
    }
  }

  public var hasPromotedRecordSubscription: Bool {
    didSet {
      storage.hasPromotedRecordSubscription = hasPromotedRecordSubscription
    }
  }

  public var recordSubscriptionStatusData: Data? {
    didSet {
      storage.recordSubscriptionStatusData = recordSubscriptionStatusData
    }
  }
}

public enum HDocTheme: Int, RawRepresentable, CaseIterable {
  case auto = 0
  case dark
  case light
}
