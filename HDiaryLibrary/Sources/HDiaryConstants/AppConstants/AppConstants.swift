//
//  AppConstants.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/13.
//

import Foundation

public enum AppConstants {
  public static let groupName = "group.com.tiger.suzhou.HDiary"
  public static let cloudKitContainerIdentifier = "iCloud.com.tigerhuahuahu.suzhou.hdiary"

  #if os(iOS)
    public static let appName = String(localized: "CFBundleDisplayName", table: "InfoPlist")
    public static let privacyUrl = "https://app.tigerpro.org/hdiary/privacy.html"

    public static let groupContainerURL: URL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: Self.groupName)!
  #endif
}

#if os(iOS)

  public extension AppConstants {
    enum IAP {
      public static let freeRecordNumber = 50
    }
  }

#endif

public extension UserDefaults {
  static let hDiaryShared = UserDefaults(suiteName: AppConstants.groupName)
}

#if os(iOS)

  public enum HDiaryIntentKind: String {
    case moment = "Moment"
  }

#endif
