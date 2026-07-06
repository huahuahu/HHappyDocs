//
//  ICloudContainer.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//
#if os(iOS)

  import Foundation
  import HDiaryConstants
  import SwiftData

  extension Schema {
    static let hDiaryScheme = Schema([Tag.self, Moment.self, MediaItem.self, Participant.self])
  }

  public enum HDiaryContainer {
    @MainActor
    public static var iCloudContainer: ModelContainer = {
      let schema = Schema.hDiaryScheme
      let configuration = ModelConfiguration(
        schema: schema,
        groupContainer: .identifier(AppConstants.groupName),
        cloudKitDatabase: .private(AppConstants.cloudKitContainerIdentifier)
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

  extension HDiaryContainer {
    @MainActor
    public static var localContainer: ModelContainer = {
      let schema = Schema.hDiaryScheme
      let containerUrl = AppConstants.groupContainerURL.appending(components: "Library", "Application Support", "localDB", "localDB", directoryHint: .notDirectory)
      let configuration = ModelConfiguration(
        schema: schema,
        url: containerUrl,
        cloudKitDatabase: .none
      )
      do {
        let container = try ModelContainer(
          for: schema,
          configurations: [configuration]
        )
        return container
      }
      catch {
        fatalError("Failed to create local container")
      }
    }()
  }

  extension HDiaryContainer {
    @MainActor
    public static func getCurrentContainer() -> ModelContainer {
      #if DEBUG
        switch UserPreferences.shared.swiftDataContainerType {
        case .iCloud:
          return HDiaryContainer.iCloudContainer
        case .local:
          return HDiaryContainer.localContainer
        case .inMemory:
          return HDiaryContainer.inMemoryPreviewContainer
        }
      #else
        return HDiaryContainer.iCloudContainer
      #endif
    }
  }

#endif
