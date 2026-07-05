//
//  AppRootView.swift
//  HDiary
//
//  Created by tigerguo on 2026/7/5.
//

import HDiaryConstants
import HDiaryServices
import SwiftData
import SwiftUI

@MainActor
struct AppRootView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.undoManager) private var undoManager
  @State private var hasPerformedStartupTask = false

  var body: some View {
    BaseTabView()
      .onAppear(perform: performStartupTasksIfNeeded)
  }

  private func performStartupTasksIfNeeded() {
    guard !hasPerformedStartupTask else {
      return
    }
    hasPerformedStartupTask = true
    Log.common.info("Performing startup task")
    StartupDataMaintenanceService().runLoggingFailures(in: modelContext)
    modelContext.undoManager = undoManager
  }
}
