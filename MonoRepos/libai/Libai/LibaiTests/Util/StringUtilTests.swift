//
//  StringUtilTests.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/5/29.
//

@testable import Libai
import XCTest

class StringUtilTests: XCTestCase {
  func testStringAllRanges() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    let testString = "李白好啊李白妙"

    let result = testString.allRanges(of: "李白")

    XCTAssertEqual(result.count, 2)
  }

  func testHighlight() {
    let testString: String? = "赐金放还，相遇杜甫。开始求道隐世，成为道士。"

    let result = testString?.highLight(keyword: "杜甫", color: .yellow)

    print("after hightlight \(String(describing: result))")
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}
