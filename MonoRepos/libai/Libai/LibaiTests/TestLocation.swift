//
//  TestLocation.swift
//  Tests iOS
//
//  Created by huahuahu on 2022/1/6.
//

@testable import Libai
import XCTest

class TestLocation: XCTestCase {
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    let location = Location(uniqueName: "碎叶城出生地", displayName: "碎叶城", currentName: "托克马克", latitude: 123, longitude: 32)

    let url = location.markdownString
    print(url)
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}

extension Location {
  var markdownString: String {
    let pattern = URLHandler.Pattern(host: .location, value: uniqueName)
    return "[\(displayName)](\(pattern.url.absoluteString))"
  }
}
