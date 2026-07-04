//
//  RecordSubscription.swift
//
//
//  Created by tigerguo on 2024/1/12.
//

import Foundation
import SwiftUI

public struct RecordSubscription {
  public var group: String

  public var monthly: String
  public var annually: String
}

public extension EnvironmentValues {
  private enum RecordSubscriptionKey: EnvironmentKey {
    static var defaultValue = RecordSubscription(
      group: "21433844",
      monthly: "hdoc_record_1m_99",
      annually: "hdoc_record_1y_990"
    )
  }

  var recordSubscription: RecordSubscription {
    get { self[RecordSubscriptionKey.self] }
    set { self[RecordSubscriptionKey.self] = newValue }
  }
}
