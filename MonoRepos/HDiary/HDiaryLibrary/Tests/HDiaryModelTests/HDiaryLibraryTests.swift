#if os(iOS)

  @testable import HDiaryModel
  import HDiaryConstants
  import HFoundation

  import XCTest

  final class HDiaryLibraryTests: XCTestCase {
    func testExample() throws {
      // XCTest Documentation
      // https://developer.apple.com/documentation/xctest

      // Defining Test Cases and Test Methods
      // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
      let groupName = AppConstants.groupName
      let icloudID = AppConstants.cloudKitContainerIdentifier
      XCTAssertNotEqual(groupName, icloudID)
    }

    func testAddUtfHeader() throws {
      // Given
      let nonUTF8HtmlString = "<h1>这是标题</h1><p>这是一段文本。</p>"

      // When
      let modifiedString = nonUTF8HtmlString.getUTF8Html()

      // Then
      let expectedString = "<html>\n <head>\n  <meta charset=\"UTF-8\">\n </head>\n <body>\n  <h1>这是标题</h1>\n  <p>这是一段文本。</p>\n </body>\n</html>"
      XCTAssertEqual(modifiedString, expectedString)
    }
  }

#endif
