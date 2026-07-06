//
//  UserPreferences.swift
//  HDiaryConstants
//
//  Created by tigerguo on 2023/4/2.
//

import Foundation
import HUIComponent
import Observation
import SwiftUI

#if os(iOS)

@MainActor @Observable
public final class UserPreferences {
  public class Storage {
    @AppStorage(UserDefaultKey.theme.rawValue, store: .hDiaryShared) public var theme: HTheme = .auto
    @AppStorage(UserDefaultKey.appLockEnabled.rawValue, store: .hDiaryShared) public var appLockEnabled = false
    @AppStorage(UserDefaultKey.hasShownRecordPromotionView.rawValue, store: .hDiaryShared) public var hasShownRecordPromotionView = false
    @AppStorage(UserDefaultKey.recordSubscriptionStatus.rawValue, store: .hDiaryShared) public var recordSubscriptionStatusData: Data?
    @AppStorage(UserDefaultKey.swiftDataContainerType.rawValue, store: .hDiaryShared) public var swiftDataContainerType = SwiftDataContainerType.iCloud
    @AppStorage(UserDefaultKey.supportSearch.rawValue, store: .hDiaryShared) public var supportSearch = true
    @AppStorage(UserDefaultKey.bypassIPRestriction.rawValue, store: .hDiaryShared) public var bypassIPRestriction = false
  }

  private let storage = Storage()

  public static let shared = UserPreferences()

  private init() {
    self.theme = storage.theme
    self.appLockEnabled = storage.appLockEnabled
    self.recordSubscriptionStatusData = storage.recordSubscriptionStatusData
    self.hasShownRecordPromotionView = storage.hasShownRecordPromotionView
    self.swiftDataContainerType = storage.swiftDataContainerType
    self.supportSearch = storage.supportSearch
    self.bypassIPRestriction = storage.bypassIPRestriction
  }

  public var theme: HTheme {
    didSet {
      storage.theme = theme
    }
  }

  public var appLockEnabled: Bool {
    didSet {
      storage.appLockEnabled = appLockEnabled
    }
  }

  public var hasShownRecordPromotionView: Bool {
    didSet {
      storage.hasShownRecordPromotionView = hasShownRecordPromotionView
    }
  }

  public var recordSubscriptionStatusData: Data? {
    didSet {
      storage.recordSubscriptionStatusData = recordSubscriptionStatusData
    }
  }

  public var swiftDataContainerType: SwiftDataContainerType {
    didSet {
      storage.swiftDataContainerType = swiftDataContainerType
    }
  }

  public var supportSearch: Bool {
    didSet {
      storage.supportSearch = supportSearch
    }
  }

  public var bypassIPRestriction: Bool {
    didSet {
      storage.bypassIPRestriction = bypassIPRestriction
    }
  }
}

#endif
