//
//  HStringHtmlTests.swift
//  HFoundationTests
//
//  Created by tigerguo on 2023/4/21.
//

@testable import HFoundation
import XCTest

final class HStringHtmlTests: XCTestCase {
  func testAddUtfHeader() throws {
    // Given
    let nonUTF8HtmlString = "<h1>这是标题</h1><p>这是一段文本。</p>"

    // When
    let modifiedString = nonUTF8HtmlString.getUTF8Html()

    // Then
    let expectedString = "<html>\n <head>\n  <meta charset=\"UTF-8\">\n </head>\n <body>\n  <h1>这是标题</h1>\n  <p>这是一段文本。</p>\n </body>\n</html>"
    XCTAssertEqual(modifiedString, expectedString)
  }

  func testChangeUtfHeader() throws {
    // Given
    let nonUTF8HtmlString = "<html>\n <head>\n  <meta charset=\"UTF-16\">\n </head>\n <body>\n  <h1>这是标题</h1>\n  <p>这是一段文本。</p>\n </body>\n</html>"

    // When
    let modifiedString = nonUTF8HtmlString.getUTF8Html()

    // Then
    let expectedString = "<html>\n <head> \n  <meta charset=\"UTF-8\"> \n </head> \n <body> \n  <h1>这是标题</h1> \n  <p>这是一段文本。</p>  \n </body>\n</html>"
    XCTAssertEqual(modifiedString, expectedString)
  }
}
