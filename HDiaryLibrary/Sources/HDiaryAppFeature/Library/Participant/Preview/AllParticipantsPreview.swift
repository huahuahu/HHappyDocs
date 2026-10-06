#if DEBUG && os(iOS)
  import SwiftUI

  struct AllParticipantsPreview: View {
    let fixture: AllParticipantsPreviewFixture
    var tintColor: Color = .accentColor
    @State private var navigationStore = {
      let store = NavigationStore()
      store.path = [.libraryEntry(entry: .participant)]
      return store
    }()

    var body: some View {
      @Bindable var navigationStore = navigationStore
      HDiaryTabShell(
        selection: .constant(.library),
        searchViewModel: .constant(fixture.searchViewModel),
        supportsSearch: false,
        content: Color.clear,
        library: NavigationStack(path: $navigationStore.path) {
          Color.clear
            .navigationTitle(Text(DiaryStringKey.libraryTabItemLabel))
            .hDiaryNavigator()
        },
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(navigationStore)
      .environment(\.locale, Locale(identifier: "zh_CN"))
      .environment(\.dynamicTypeSize, fixture.scenario == .accessibility ? .accessibility3 : .large)
      .environment(\.colorScheme, fixture.scenario == .dark ? .dark : .light)
      .tint(tintColor)
      .transaction { $0.animation = nil }
    }
  }
#endif
