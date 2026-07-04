//
//  SwiftDataDebugView.swift
//  HDiary
//
//  Created by tigerguo on 2025/1/10.
//

import HDiaryConstants
import HDiaryModel
import SwiftUI

@MainActor
struct SwiftDataDebugView: View {
  @Environment(UserPreferences.self) private var userPreferences
  // https://developer.apple.com/forums/thread/757521
  // When an @ModelActor is created and later released (for example dropped at the end of a function scope), the model instances fetched by its associated model context can't be meaningfully used anymore.

  @State private var message: String?
  var body: some View {
    @Bindable var userPreferences = userPreferences
    ZStack {
      List {
        Picker(selection: $userPreferences.swiftDataContainerType) {
          ForEach(SwiftDataContainerType.allCases) { containerType in
            Text(verbatim: containerType.textInLabel)
              .tag(containerType)
          }
        } label: {
          Text(verbatim: "Container Type")
        }
        clearDataButton
        if userPreferences.swiftDataContainerType != .inMemory {
          insertSampleDataButton
        }
        InsertMomentButton(message: $message, sampleDataHandler: sampleDataHandler)
      }
      StatusView(message: $message)
    }
    .navigationTitle(Text(verbatim: "SwiftData Debug"))
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private var clearDataButton: some View {
    Button {
//        DispatchQueue.global(qos: .default).async {
      message = "Clearing data..."
      Task.detached {
        do {
          try await sampleDataHandler.clearAllData()
          await MainActor.run {
            message = "Data cleared successfully"
          }
        }
        catch {
          Log.data.error("Failed to clear data: \(error)")
          await MainActor.run {
            message = "Failed to clear data: \(error)"
          }
        }
      }
//        }
    } label: {
      Text(verbatim: "Clear Data")
    }
  }

  @ViewBuilder
  private var insertSampleDataButton: some View {
    Button {
      message = "Inserting sample data..."
      Task.detached {
        do {
          try await sampleDataHandler.insertSampleData()
          await MainActor.run {
            message = "Sample data inserted successfully"
          }
        }
        catch {
          Log.data.error("Failed to insert sample data: \(error)")
          await MainActor.run {
            message = "Failed to insert sample data: \(error)"
          }
        }
      }
    } label: {
      Text(verbatim: "Insert Sample Data")
    }
  }

  private var sampleDataHandler: SampleDataHandler {
    #if DEBUG
      switch UserPreferences.shared.swiftDataContainerType {
      case .iCloud:
        return SampleDataHandler.cloudDataHandler
      case .local:
        return SampleDataHandler.localDataHandler
      case .inMemory:
        return SampleDataHandler.inMemoryDataHandler
      }
    #else
      return SampleDataHandler.cloudDataHandler
    #endif
  }
}

extension SwiftDataContainerType {
  var textInLabel: String {
    switch self {
    case .iCloud:
      return "iCloud"
    case .local:
      return "Local"
    case .inMemory:
      return "In Memory"
    }
  }
}

#Preview("SwiftDataDebugView", body: {
  NavigationStack {
    SwiftDataDebugView()
  }
  .previewEnvironment()
})
