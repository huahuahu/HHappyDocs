// The Swift Programming Language
// https://docs.swift.org/swift-book

#if os(iOS)

  import Foundation
  import LibaiAppConstants
  import SwiftData

  extension Schema {
    static let libaiScheme = Schema([FavPoem.self])
  }

  public enum LibaiContainer {
    public static var iCloudContainer: ModelContainer = {
      let schema = Schema.libaiScheme
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

//    public static let allModelTypes: [any PersistentModel.Type] = [MedicalSite.self, MedicalStaff.self, Record.self, Symptom.self]
  }

#endif
