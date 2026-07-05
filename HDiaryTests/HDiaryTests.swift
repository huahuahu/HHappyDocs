//
//  HDiaryTests.swift
//  HDiaryTests
//
//  Created by tigerguo on 2023/6/17.
//

@testable import HDiary
import SwiftUI
import XCTest

@MainActor
final class HDiaryTests: XCTestCase {
  func testAppRootViewCanBeConstructed() {
    let view = AppRootView()

    XCTAssertEqual(String(describing: type(of: view)), "AppRootView")
  }
}
