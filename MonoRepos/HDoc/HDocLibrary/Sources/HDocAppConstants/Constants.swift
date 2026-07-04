// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import HFoundation

public enum AppConstants {
  public static let groupName = "group.com.tiger.suzhou.HDoc"
  public static let cloudKitContainerIdentifier = "iCloud.com.tiger.suzhou.hdoc"
  public static let appName = String(localized: "CFBundleDisplayName", table: "InfoPlist")

  public static let appNameForOpenLocation = "com.tiger.suzhou.hdoc"

  public enum IAP {
    public static let freeRecordNumber = 5000
  }

  public static let privacyUrl = "https://app.tigerpro.org/hdoc/privacy.html"
}
