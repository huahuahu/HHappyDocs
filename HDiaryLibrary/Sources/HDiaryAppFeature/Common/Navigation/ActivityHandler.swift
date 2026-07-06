//
//  ActivityHandler.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

#if os(iOS)

import Foundation
import SwiftUI

protocol ActivityHandler {
  func handle(_ activity: NSUserActivity, mutating: inout [HDiaryDestination])
}

final class ActivityHandlerImpl: ActivityHandler {
  func handle(_ activity: NSUserActivity, mutating path: inout [HDiaryDestination]) {}
}

#endif
