//
//  Container.swift
//
//
//  Created by tigerguo on 2023/12/29.
//

#if os(iOS)

  import Foundation
  import HDocAppConstants
  import SwiftData

  extension Schema {
    static let hDocScheme = Schema([MedicalStaff.self, Record.self, Symptom.self])
  }

  public enum HDocContainer {
    public static var iCloudContainer: ModelContainer = {
      let schema = Schema.hDocScheme
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

    public static let allModelTypes: [any PersistentModel.Type] = [MedicalSite.self, MedicalStaff.self, Record.self, Symptom.self, Location.self]
  }

#endif
