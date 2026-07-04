//
//  TestCombine.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/3/13.
//

import Combine
import XCTest

class TestCombine: XCTestCase {
  @Published var testValue = 1

  private var subscritpions = Set<AnyCancellable>()

  func testExample() async throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    testValue = 8
    $testValue
      .sink { newValue in
        print("huahuahu \(newValue)")
      }
      .store(in: &subscritpions)

    update($testValue)
    await asyncUpdate()
  }

  private func asyncUpdate() async {
    testValue = 9
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    testValue = 2
    testValue = 3
  }

  private func update(_ publisher: Published<Int>.Publisher) {
    let shared = publisher.share()
    shared
      .sink { newValue in
        print("huahuahu \(#function), newValue \(newValue)")
      }
      .store(in: &subscritpions)

    shared
      .throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
      .sink { newValue in
        print("huahuahu throttle\(#function), newValue \(newValue)")
      }
      .store(in: &subscritpions)
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
}
