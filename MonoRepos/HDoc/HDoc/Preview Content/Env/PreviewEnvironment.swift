//
//  PreviewEnvironment.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation
import HDocAppConstants
import HDocLocation
import HDocModel
import SwiftData
import SwiftUI

extension View {
  @MainActor
  func previewEnvironment() -> some View {
    return self.environment(UserPreferences.shared)
      .hDocNavigator()
      .modelContainer(HDocContainer.previewContainer)
      .environment(NavigationStore())
      .environment(HDocLocationManager())
  }
}

// extension
public struct SampleDataModifier: PreviewModifier {
  public init() {}
  public static func makeSharedContext() throws -> ModelContainer {
    let container = HDocContainer.previewContainer
    return container
  }

  public func body(content: Content, context: ModelContainer) -> some View {
    content.modelContainer(context)
      .environment(NavigationStore())
  }
}
