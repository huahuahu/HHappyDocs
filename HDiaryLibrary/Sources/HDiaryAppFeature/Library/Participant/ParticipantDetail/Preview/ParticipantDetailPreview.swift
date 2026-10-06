#if DEBUG && os(iOS)
  import SwiftUI

  struct ParticipantDetailPreview: View {
    let fixture: ParticipantDetailPreviewFixture
    @State private var navigationStore: NavigationStore

    init(fixture: ParticipantDetailPreviewFixture) {
      self.fixture = fixture
      let store = NavigationStore()
      store.path = [.participant(fixture.participant)]
      navigationStore = store
    }

    var body: some View {
      @Bindable var navigationStore = navigationStore
      HDiaryTabShell(
        selection: .constant(.library),
        searchViewModel: .constant(fixture.searchViewModel),
        supportsSearch: false,
        content: Color.clear,
        library: NavigationStack(path: $navigationStore.path) {
          HDiaryDestination.libraryEntry(entry: .participant).targetView
            .hDiaryNavigator()
        },
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(navigationStore)
      .environment(\.locale, Locale(identifier: "zh_CN"))
      .environment(\.dynamicTypeSize, fixture.scenario == .accessibility ? .accessibility3 : .large)
      .environment(\.colorScheme, fixture.scenario == .dark ? .dark : .light)
      .scrollIndicators(.hidden)
      .transaction { $0.animation = nil }
    }
  }
#endif
