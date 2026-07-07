//
//  LibraryView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import SwiftUI

@MainActor
struct LibraryView: View {
  @Environment(HDiaryRoute.self) private var appRoute
//  @Environment(NavigationStore.self) private var navigationStore
  @Binding private var isSelected: Bool
  init(isSelected: Binding<Bool>) {
    self._isSelected = isSelected
  }

  var body: some View {
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.libraryNavigationStore.path) {
      List {
        ForEach(LibraryEntry.allCases) {
          entry in
          NavigationLink(value: HDiaryDestination.libraryEntry(entry: entry)) {
            LibraryEntryCell(entry: entry)
          }
        }
      }
      .navigationDestination(for: HDiaryDestination.self) { destination in
        destination.targetView
      }
//      .withSheetDestinations(sheetDestinations: $navigationStore.presentedSheet)
      .onOpenURL(perform: { url in
        if self.isSelected {
          Log.Navigation.common.info("handle url in library tab")
          appRoute.libraryNavigationStore.handle(url)
        }
      })
      .navigationTitle(Text(DiaryStringKey.libraryTabItemLabel))
    }
    .environment(appRoute.libraryNavigationStore)
  }
}

#Preview {
  LibraryView(isSelected: .constant(true))
    .previewEnvironment()
}

#endif
