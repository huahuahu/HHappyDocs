//
//  Store.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/21.
//

import Foundation
import Observation

@Observable
final class Store {
  var models: [Target: [ArtWorkModel]] = [:]

  func add(_ model: ArtWorkModel, to target: Target) {
    if models[target] == nil {
      models[target] = []
    }
    models[target]?.append(model)
  }

  func remove(_ model: ArtWorkModel, from target: Target) {
    models[target]?.removeAll { $0.id == model.id }
  }

  static func getDataRepresentation(for store: Store) throws -> Data {
    let models = store.models
    let data = try JSONEncoder().encode(ModelData(models: models))
    return data
  }

  static func fromData(_ data: Data) throws -> Store {
    let modelData = try JSONDecoder().decode(ModelData.self, from: data)
    let store = Store()
    store.models = modelData.models
    return store
  }
}

private struct ModelData: Codable {
  let models: [Target: [ArtWorkModel]]
}
