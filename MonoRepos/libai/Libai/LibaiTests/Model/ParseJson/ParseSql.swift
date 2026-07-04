//
//  ParseSql.swift
//  LibaiTests
//
//  Created by tigerguo on 2023/2/20.
//

@testable import Libai
import XCTest

final class ParseSql: XCTestCase {
  func testParseEmpire() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    let empireUrl = Bundle(for: Self.self).url(forResource: "empire", withExtension: "json")!

    let data = try Data(contentsOf: empireUrl, options: [])
    _ = try JSONDecoder().decode([Empire].self, from: data)
    print("result")
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}
