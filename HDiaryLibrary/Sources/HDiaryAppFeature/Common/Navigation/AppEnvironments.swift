//
//  AppEnvironments.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/28.
//

#if os(iOS)

import Foundation
import HDiaryConstants
import HDiaryIAP
import HDiaryModel
import HDiarySearch
import HUIComponent
import Observation
import SwiftData
import SwiftUI

@MainActor
extension View {
  func withEnvironments() -> some View {
    modifier(HDiaryEnvironmentModifier())
  }

  func withModelContainer() -> some View {
    modelContainer(HDiaryContainer.currentContainer)
  }

  func previewEnvironment() -> some View {
    environment(NavigationStore())
      .recordSubscriptionPassStatusTask()
      .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
      .environment(UserPreferences.shared)
      .environment(HDiaryRoute.shared)
      .environment(MomentCloudStateManager.shared)
      .environment(SearchViewModel())
  }
}

struct HDiaryEnvironmentModifier: ViewModifier {
  func body(content: Content) -> some View {
    @Bindable var userPreferences = UserPreferences.shared
    @Bindable var momentCloudStateManager = MomentCloudStateManager.shared

    content
      .theme(userPreferences.theme)
      .hDiaryLocalAuth(needAuth: userPreferences.appLockEnabled)
      .recordSubscriptionPassStatusTask()
      .environment(userPreferences)
      .environment(HDiaryRoute.shared)
      .environment(momentCloudStateManager)
  }
}

#endif
