//
//  IAPString.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

#if os(iOS)

  import Foundation

  enum IAPString {
    public static let yearlySubscription = LocalizedStringResource("iap.currentStatus.yearlySubscription", table: "Localizable", comment: "shown when current status is annually subscription")
    public static let subscibe = LocalizedStringResource("iap.subscribe", table: "Localizable", comment: "shown when no subscription")
    public static let upgradeToYearlySubscription = LocalizedStringResource("iap.upgradeToYearlySubscription", table: "Localizable", comment: "shown when current it monthly subscription and want user to upgrade to yearly subscription")
    public static let restore = LocalizedStringResource("iap.restore", table: "Localizable", comment: "shown when user want to restore purchase")

    public static let restoreSuccess = LocalizedStringResource("iap.restore.result.success", table: "Localizable", comment: "shown in alert shown when user restore succeed")
    public static let restoreFail = LocalizedStringResource("iap.restore.result.fail", table: "Localizable", comment: "shown in alert shown when user restore failed")

    public static let subscriptionViewTitle = LocalizedStringResource("iap.subscriptionView.title", table: "Localizable", comment: "shown as title in subscriptioni view for unlimited record")

    public static let cancel = LocalizedStringResource("iap.common.cancel", table: "Localizable", comment: "general cancel ")
  }

  extension LocalizedStringResource {
    func hDocLocalized() -> String {
      String(localized: .init(stringLiteral: self.key), bundle: .module)
    }
  }

#endif
