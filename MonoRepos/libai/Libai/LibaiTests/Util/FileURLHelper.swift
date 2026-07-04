//
//  FileURLHelper.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/4/16.
//

@testable import Libai
import XCTest

class FileURL: XCTestCase {
  func testExample() throws {
    // This is an example of a functional test case.
    let tempUrl = FileURLHelper.getTempUrl()
    print("tempUrl \(tempUrl)")
  }
}
