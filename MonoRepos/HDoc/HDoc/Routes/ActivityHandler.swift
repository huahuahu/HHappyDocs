//
//  ActivityHandler.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/26.
//

import Foundation
import SwiftUI

protocol ActivityHandler {
  func handle(_ activity: NSUserActivity, mutating: inout [HDocNavigationTarget])
}

final class ActivityHandlerImpl: ActivityHandler {
  func handle(_ activity: NSUserActivity, mutating path: inout [HDocNavigationTarget]) {}
}
