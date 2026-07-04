//
//  Route.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//

import Observation
import SwiftUI

@MainActor
@Observable final class NavigationStore {
  var path = [NavigationTarget]()
}

enum NavigationTarget: Hashable {
  case test
}

extension NavigationTarget {
  @MainActor @ViewBuilder
  var destination: some View {
    switch self {
    case .test:
      Text(verbatim: "Home")
    }
  }
}
