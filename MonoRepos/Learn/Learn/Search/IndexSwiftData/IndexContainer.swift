//
//  IndexContainer.swift
//  Learn
//
//  Created by tigerguo on 2025/1/27.
//

import SwiftData

extension SearchDemo {
  enum IndexContainer {
    static let icloudContainer: ModelContainer = {
      let schema = Schema([SearchDemo.Incident.self])
      let configuration = ModelConfiguration(
        schema: schema,
        groupContainer: .identifier("group.com.tiger.suzhou.learn"),
        cloudKitDatabase: .private("iCloud.com.tiger.suzhou.learn")
      )
      do {
        let container = try ModelContainer(
          for: schema,
          configurations: [configuration]
        )
        return container
      }
      catch {
        fatalError("Failed to create icloud container")
      }
    }()
  }
}
