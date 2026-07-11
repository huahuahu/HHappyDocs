import SwiftUI

enum RecordFeatureAccessPolicy {
  static func allowsAccess(
    for status: RecordSubscriptionStatus,
    distribution: AppDistribution
  ) -> Bool {
    if distribution == .testFlight {
      return true
    }

    switch status {
    case .notSubscribed:
      return false
    case .monthly, .annually:
      return true
    }
  }
}

public extension EnvironmentValues {
  enum RecordFeatureAccessAllowedEnvironmentKey: EnvironmentKey {
    public static let defaultValue = false
  }

  var recordFeatureAccessAllowed: Bool {
    get { self[RecordFeatureAccessAllowedEnvironmentKey.self] }
    set { self[RecordFeatureAccessAllowedEnvironmentKey.self] = newValue }
  }
}
