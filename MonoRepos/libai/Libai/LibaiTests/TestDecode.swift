//
//  TestDecode.swift
//  Tests iOS
//
//  Created by huahuahu on 2021/12/27.
//

import XCTest

class TestDecode: XCTestCase {
  func testDecodeNullFromJS() throws {
    let string = #"{"a":1,"b":null}"#

    struct Test: Decodable {
      let a: Int
      let b: Int?
    }
    print("huahuahu \(String(describing: testDecodeNullFromJS))")
    do {
      let data = string.data(using: .utf8)!

      let decoded = try JSONDecoder().decode(Test.self, from: data)
      print(decoded)
    }
    catch {
      print(error)
    }
  }
}
