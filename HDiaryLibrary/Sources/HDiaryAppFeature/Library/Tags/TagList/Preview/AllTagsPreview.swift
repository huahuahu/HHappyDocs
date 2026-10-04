#if DEBUG && os(iOS)
  import SwiftUI

  struct AllTagsPreview: View {
    let fixture: AllTagsPreviewFixture
    @State private var path: [HDiaryDestination] = [.libraryEntry(entry: .tag)]

    var body: some View {
      HDiaryTabShell(
        selection: .constant(.library),
        searchViewModel: .constant(fixture.searchViewModel),
        supportsSearch: false,
        content: Color.clear,
        library: NavigationStack(path: $path) {
          Color.clear
            .navigationTitle(Text(DiaryStringKey.libraryTabItemLabel))
            .hDiaryNavigator()
        },
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(\.calendar, AllTagsPreviewFixture.calendar)
      .environment(\.timeZone, AllTagsPreviewFixture.calendar.timeZone)
      .environment(\.locale, Locale(identifier: "zh_CN"))
      .environment(\.dynamicTypeSize, fixture.scenario.dynamicTypeSize)
      .environment(\.colorScheme, fixture.scenario.colorScheme)
      .tint(.orange)
      .scrollIndicators(.hidden)
      .transaction { $0.animation = nil }
    }
  }

  #Preview("标签 · 空列表") {
    AllTagsPreview(fixture: try! AllTagsPreviewFixture(scenario: .empty))
  }

  #Preview("标签 · 普通列表") {
    AllTagsPreview(fixture: try! AllTagsPreviewFixture(scenario: .populated))
  }

  #Preview("标签 · 长名称") {
    AllTagsPreview(fixture: try! AllTagsPreviewFixture(scenario: .longNames))
  }

  #Preview("标签 · 深色模式") {
    AllTagsPreview(fixture: try! AllTagsPreviewFixture(scenario: .dark))
  }

  #Preview("标签 · 辅助功能字号") {
    AllTagsPreview(fixture: try! AllTagsPreviewFixture(scenario: .accessibility))
  }
#endif
