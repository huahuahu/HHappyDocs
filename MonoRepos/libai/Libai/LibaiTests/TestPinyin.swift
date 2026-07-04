//
//  TestPinyin.swift
//  Tests iOS
//
//  Created by huahuahu on 2021/12/27.
//

@testable import Libai
import XCTest

class TestPinyin: XCTestCase {
  func testPinyin() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

    func printPinyin(_ string: String) {
      print("\(string) -> \(String(describing: string.transformToPinyin()))")
    }

    [
      "你好",
      "您好",
      "李白",
      "西藏",
      "胀肚子",
    ].forEach { printPinyin($0) }
  }

  func testCharIndex() {
//        4e00-9fbb
    let range = 0x4E00 ... 0x9FBB
    for scalar in range {
      guard let unicode = UnicodeScalar(scalar) else {
        fatalError()
      }
      let char = Character(unicode)
      _ = String(char).getFirstCharIndex()
    }
  }
}

extension String {
  func transformToPinyin() -> String? {
    applyingTransform(.mandarinToLatin, reverse: false)
  }
}
