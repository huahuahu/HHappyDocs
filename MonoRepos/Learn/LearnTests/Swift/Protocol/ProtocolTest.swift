//
//  ProtocolTest.swift
//  LearnTests
//
//  Created by tigerguo on 2023/4/9.
//

import XCTest

final class ProtocolTest: XCTestCase {
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  // https://www.hackingwithswift.com/articles/138/swift-protocols-tips-and-tricks
//    Declaring our method inside the protocol creates what Swift calls an extension point – a method that we encourage conforming types to override. If we put methods into the extension but not the protocol, all conforming types still get the method, except now we’re making it harder for them to override.
  func testExtension() throws {
    let seniorDeveloper = SeniorDeveloper()
    XCTAssertEqual(seniorDeveloper.kind, "Senior developer")
    let developer: Developer = SeniorDeveloper()
    XCTAssertEqual(developer.kind, "developer")
  }
}

protocol Developer {}

extension Developer {
  var kind: String { "developer" }
}

struct SeniorDeveloper: Developer {
  var kind: String { "Senior developer" }
}
