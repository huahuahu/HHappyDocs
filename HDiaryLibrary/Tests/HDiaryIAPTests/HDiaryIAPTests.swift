#if os(iOS)

  @testable import HDiaryIAP
  import XCTest

  final class HDiaryIAPTests: XCTestCase {
    func testPhysicalSandboxReceiptWithoutProfileIsTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "sandboxReceipt",
        hasEmbeddedMobileProvision: false,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .testFlight)
    }

    func testProductionReceiptIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "receipt",
        hasEmbeddedMobileProvision: false,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .other)
    }

    func testEmbeddedProvisioningProfileIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "sandboxReceipt",
        hasEmbeddedMobileProvision: true,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .other)
    }

    func testSimulatorIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "sandboxReceipt",
        hasEmbeddedMobileProvision: false,
        isSimulator: true
      )

      XCTAssertEqual(distribution, .other)
    }

    func testMissingReceiptIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: nil,
        hasEmbeddedMobileProvision: false,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .other)
    }
  }

#endif
