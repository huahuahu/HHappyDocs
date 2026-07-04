//
//  LibraryEntryView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocAppConstants
import SwiftUI

@MainActor
struct LibraryEntryView: View {
//  @State private var navigationStore = NavigationStore()
  @Environment(AppRoute.self) private var appRoute

  var body: some View {
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.libraryNavigationStore.path) {
      List {
        ForEach(LibraryEntry.allCases) { entry in
          NavigationLink(value: entry.desitination) {
            Label(
              title: { Text(entry.label) },
              icon: { Image(hdocSymbol: entry.symbol) }
            )
          }
        }
      }
      .navigationDestination(for: HDocNavigationTarget.self, destination: { target in
        target.getTargetView()
      })
      .navigationTitle(Text(HDocString.Common.library))
    }
    .environment(appRoute.libraryNavigationStore)
  }
}

#if DEBUG
  #Preview {
    LibraryEntryView()
      .previewEnvironment()
  }

#endif
