#if DEBUG && os(iOS)
  import SwiftUI

  /// Reuses the app's list, destination registration and Tab shell without app startup services.
  struct MomentDetailPreview: View {
    let fixture: MomentDetailPreviewFixture
    @State private var navigationStore: NavigationStore

    init(fixture: MomentDetailPreviewFixture) {
      self.fixture = fixture
      let store = NavigationStore()
      store.path = [.moment(fixture.moment, editEnabled: true)]
      navigationStore = store
    }

    var body: some View {
      @Bindable var navigationStore = navigationStore
      HDiaryTabShell(
        selection: .constant(.content),
        searchViewModel: .constant(fixture.searchViewModel),
        supportsSearch: true,
        content: NavigationStack(path: $navigationStore.path) {
          MomentListScreen(
            referenceDate: MomentDetailPreviewFixture.referenceDate,
            initiallyExpanded: true
          )
          .navigationTitle(Text(DiaryStringKey.happyListNavigationTitle))
          .hDiaryScrollingNavigationBar()
        },
        library: Color.clear,
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(navigationStore)
      .environment(fixture.cloudState)
      .environment(\.calendar, MomentDetailPreviewFixture.calendar)
      .environment(\.timeZone, MomentDetailPreviewFixture.calendar.timeZone)
      .environment(\.locale, Locale(identifier: "zh_CN"))
      .environment(\.dynamicTypeSize, fixture.scenario.dynamicTypeSize)
      .environment(\.colorScheme, fixture.scenario == .dark ? .dark : .light)
    }
  }

#endif
