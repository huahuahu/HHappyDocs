//
//  SectionDataWithIndexTests.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/4/10.
//

@testable import Libai
import XCTest

class SectionDataWithIndexTests: XCTestCase {
  func testExample() throws {
    // Given
    let items: [Item] = ["安陵", "安陆", "汴州", "采石矶", "长安"]

    // When
    let sections = SectionDataWithIndex.sectionDataArray(from: items) { item in
      item.str.transformToPinyin()!.folding(options: .diacriticInsensitive, locale: .current).uppercased().first!
    }

    // Then
    XCTAssertEqual(sections.count, 4)
    XCTAssertEqual(sections[0].charIndex, "A")
    XCTAssertEqual(sections[0].items, [Item("安陵"), Item("安陆")])
    XCTAssertEqual(sections[1].charIndex, "B")
    XCTAssertEqual(sections[1].items, [Item("汴州")])

    XCTAssertEqual(sections[2].charIndex, "C")
    XCTAssertEqual(sections[2].items, [Item("采石矶")])

    XCTAssertEqual(sections[3].charIndex, "Z")
    XCTAssertEqual(sections[3].items, [Item("长安")])
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}

struct Item: Identifiable, Equatable {
  let str: String
  init(_ str: String) {
    self.str = str
  }

  var id: String {
    str
  }
}

extension Item: ExpressibleByStringLiteral {
  typealias StringLiteralType = String

  init(stringLiteral value: Self.StringLiteralType) {
    self.init(value)
  }
}
