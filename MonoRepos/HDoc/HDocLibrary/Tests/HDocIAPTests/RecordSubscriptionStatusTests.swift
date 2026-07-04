//
//  RecordSubscriptionStatusTests.swift
//
//
//  Created by tigerguo on 2024/1/12.
//

@testable import HDocIAP
import XCTest

final class RecordSubscriptionStatusTests: XCTestCase {
  let testSubscription = RecordSubscription(group: "test-group", monthly: "monthly", annually: "annually")
  func testCompare() throws {
    let monthly = try XCTUnwrap(RecordSubscriptionStatus.monthly(expirationDate: Date().addingTimeInterval(6 * 30 * 24 * 60 * 60)))
    let yearly = try XCTUnwrap(RecordSubscriptionStatus.annually(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60)))
    let unsubscribed = RecordSubscriptionStatus.notSubscribed
    XCTAssertGreaterThan(yearly, monthly)
    XCTAssertGreaterThan(monthly, unsubscribed)
  }
}
