//
//  DebugDetailView.swift
//  HDiary
//
//  Created by tigerguo on 2024/3/28.
//

#if os(iOS)

import SwiftUI

@MainActor
struct DebugDetailView: View {
  var body: some View {
    List(DebugEntry.allCases) { entry in
      NavigationLink(value: HDiaryDestination.debugEntry(entry: entry)) {
        Text(entry.title)
      }
    }
    .navigationTitle(Text(verbatim: "Debug View"))
  }
}

#Preview {
  NavigationStack {
    DebugDetailView()
  }
}

enum DebugEntry: Hashable, CaseIterable, Identifiable {
  case rawData
  case collectLog
  case swiftData
  case search
  case iap

  var title: String {
    switch self {
    case .rawData:
      "Raw Data"
    case .collectLog:
      "Collect Log"
    case .swiftData:
      "Swift Data Debugger"
    case .search:
      "Search"
    case .iap:
      "IAP"
    }
  }

  var id: Self { self }

  @MainActor @ViewBuilder
  var destinationView: some View {
    switch self {
    case .rawData:
      RawDataView()
    case .collectLog:
      CollectLogView()
    case .swiftData:
      SwiftDataDebugView()
    case .search:
      SettingsView.SearchDebugScreen()
    case .iap:
      SettingsView.IAPDebugScreen()
    }
  }
}

#endif
