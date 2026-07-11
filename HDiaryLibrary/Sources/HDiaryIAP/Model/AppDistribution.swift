import Foundation

enum AppDistribution: Equatable, Sendable {
  case testFlight
  case other

  static func classify(
    receiptLastPathComponent: String?,
    hasEmbeddedMobileProvision: Bool,
    isSimulator: Bool
  ) -> Self {
    guard !isSimulator,
          receiptLastPathComponent == "sandboxReceipt",
          !hasEmbeddedMobileProvision
    else {
      return .other
    }

    return .testFlight
  }

  static var current: Self {
    #if targetEnvironment(simulator)
      let isSimulator = true
    #else
      let isSimulator = false
    #endif

    return classify(
      receiptLastPathComponent: Bundle.main.appStoreReceiptURL?.lastPathComponent,
      hasEmbeddedMobileProvision: Bundle.main.url(
        forResource: "embedded",
        withExtension: "mobileprovision"
      ) != nil,
      isSimulator: isSimulator
    )
  }
}
