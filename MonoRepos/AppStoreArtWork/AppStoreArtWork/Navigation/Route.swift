//
//  Route.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import Observation

@Observable
final class Route {
  var selectedTarget: Target?

  init(selectedTarget: Target? = nil) {
    self.selectedTarget = selectedTarget
  }
}
