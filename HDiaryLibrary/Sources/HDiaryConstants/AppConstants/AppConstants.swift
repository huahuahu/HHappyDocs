//
//  AppConstants.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/13.
//
#if os(iOS)

  import Foundation

  public enum AppConstants {
    public static let groupName = "group.com.tiger.suzhou.HDiary"
    public static let cloudKitContainerIdentifier = "iCloud.com.tigerhuahuahu.suzhou.hdiary"
    public static let appName = String(localized: "CFBundleDisplayName", table: "InfoPlist")
    public static let privacyUrl = "https://app.tigerpro.org/hdiary/privacy.html"

    public static let groupContainerURL: URL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: Self.groupName)!
  }

  public extension AppConstants {
    enum IAP {
      public static let freeRecordNumber = 50
    }
  }

  public extension UserDefaults {
    static var hDiaryShared: UserDefaults? {
      UserDefaults(suiteName: AppConstants.groupName)
    }
  }

  public enum HDiaryIntentKind: String {
    case moment = "Moment"
  }

#endif
