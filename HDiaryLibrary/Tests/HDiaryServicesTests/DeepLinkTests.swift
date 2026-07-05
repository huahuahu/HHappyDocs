@testable import HDiaryServices
import XCTest

final class DeepLinkTests: XCTestCase {
  func testAddMomentURLUsesStableSchemeHostAndPath() throws {
    let url = try XCTUnwrap(DeepLink.getAddMomentUrl())

    XCTAssertEqual(url.scheme, "hdiarydl")
    XCTAssertEqual(url.host(percentEncoded: false), "moment")
    XCTAssertEqual(url.path(percentEncoded: false), "/add")
    XCTAssertEqual(url.absoluteString, "hdiarydl://moment/add")
  }

  func testMomentHostRawValueMatchesExistingAppRoutes() {
    XCTAssertEqual(DeepLink.Host.moment.rawValue, "moment")
    XCTAssertEqual(DeepLink.Host.library.rawValue, "library")
    XCTAssertEqual(DeepLink.Host.setting.rawValue, "setting")
  }

  func testMomentTargetRawValueMatchesExistingAddRoute() {
    XCTAssertEqual(DeepLink.MomentTarget.add.rawValue, "add")
  }
}
