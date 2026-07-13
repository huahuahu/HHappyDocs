//
//  LibraryView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import HDiaryConstants
import SwiftData
import SwiftUI

@MainActor
struct LibraryView: View {
  private static let maximumContentWidth: CGFloat = 720

  @Environment(HDiaryRoute.self) private var appRoute
  @Environment(\.modelContext) private var modelContext
  @State private var countModel = LibraryViewCountModel()
  @ScaledMetric(relativeTo: .body) private var contentMargin: CGFloat = 16
  @Binding private var isSelected: Bool

  init(isSelected: Binding<Bool>) {
    self._isSelected = isSelected
  }

  var body: some View {
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.libraryNavigationStore.path) {
      ScrollView {
        LibraryEntryDashboard(
          viewState: countModel.viewState
        )
        .frame(maxWidth: Self.maximumContentWidth)
        .frame(maxWidth: .infinity)
      }
      .task {
        countModel.updateCounts(modelContext: modelContext)
      }
      .contentMargins(.horizontal, contentMargin, for: .scrollContent)
      .contentMargins(.vertical, contentMargin, for: .scrollContent)
      .navigationDestination(for: HDiaryDestination.self) { destination in
        destination.targetView
      }
      .onOpenURL { url in
        if isSelected {
          Log.Navigation.common.info("handle url in library tab")
          appRoute.libraryNavigationStore.handle(url)
        }
      }
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
