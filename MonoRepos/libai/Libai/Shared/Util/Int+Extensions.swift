//
//  Int+Extensions.swift
//  Libai
//
//  Created by huahuahu on 2022/3/12.
//

import Foundation

extension Int {
  var inNanoSeconds: UInt64 {
    UInt64(self * 1_000_000_000)
  }
}
