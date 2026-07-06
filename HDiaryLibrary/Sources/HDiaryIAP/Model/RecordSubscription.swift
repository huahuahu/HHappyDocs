//
//  RecordSubscription.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation
import SwiftUI

public struct RecordSubscription: Sendable {
  public var group: String

  public var monthly: String
  public var annually: String
}

public extension EnvironmentValues {
  private enum RecordSubscriptionKey: EnvironmentKey {
    static let defaultValue = RecordSubscription(
      group: "21462545",
      monthly: "hdiary_unlimited_moments_1m_99",
      annually: "hdiary_unlimited_moments_1y_699"
    )
  }

  var recordSubscription: RecordSubscription {
    get { self[RecordSubscriptionKey.self] }
    set { self[RecordSubscriptionKey.self] = newValue }
  }
}
