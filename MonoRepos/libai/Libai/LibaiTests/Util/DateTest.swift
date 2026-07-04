//
//  DateTest.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/5/8.
//

import XCTest

class DateTest: XCTestCase {
  func testStartOfDay() throws {
    let date = Date()
    let startOfDay = Calendar.current.startOfDay(for: date)
    print("\(date), today \(startOfDay)")
    print("end")
  }
}
