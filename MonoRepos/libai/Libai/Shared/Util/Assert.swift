//
//  Assert.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/18.
//

import Foundation

func hAssertFailure(_ message: @autoclosure () -> String) {
  assertionFailure(message())
}

func hAssertion(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String) {
  assert(condition(), message())
}
