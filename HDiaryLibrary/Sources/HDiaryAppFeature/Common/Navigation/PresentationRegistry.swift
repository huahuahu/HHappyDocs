//
//  PresentationRegistry.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/28.
//

import Foundation
import SwiftUI

enum SheetDestination: Identifiable {
  case addMomnet(uuid: UUID)

  var id: String {
    switch self {
    case .addMomnet(let uuid):
      return "addMoment-\(uuid.uuidString)"
    }
  }
}
