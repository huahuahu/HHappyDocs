#if DEBUG && os(iOS)
  import SwiftUI

  struct TagDetailPreview: View {
    let fixture: TagDetailPreviewFixture
    @State private var path: [HDiaryDestination]

    init(fixture: TagDetailPreviewFixture) {
      self.fixture = fixture
      path = [.tag(tag: fixture.tag)]
    }

    var body: some View {
      HDiaryTabShell(
        selection: .constant(.library),
        searchViewModel: .constant(fixture.searchViewModel),
        supportsSearch: false,
        content: Color.clear,
        library: NavigationStack(path: $path) {
          HDiaryDestination.libraryEntry(entry: .tag).targetView
            .navigationDestination(for: HDiaryDestination.self) { destination in
              // A preloaded path skips the parent's navigation-bar transition.
              // Match the inline state reached by navigating through the tag list.
              destination.targetView
                .navigationBarTitleDisplayMode(.inline)
            }
        },
        settings: Color.clear
      )
      .modelContainer(fixture.container)
      .environment(\.calendar, TagDetailPreviewFixture.calendar)
      .environment(\.timeZone, TagDetailPreviewFixture.calendar.timeZone)
      .environment(\.locale, Locale(identifier: "zh_CN"))
      .environment(\.dynamicTypeSize, fixture.scenario.dynamicTypeSize)
      .environment(\.colorScheme, fixture.scenario.colorScheme)
      .scrollIndicators(.hidden)
      .transaction { $0.animation = nil }
    }
  }

  #Preview("标签详情 · 城市") {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .populated))
  }

  #Preview("标签详情 · 无乐事") {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .empty))
  }

  #Preview("标签详情 · 长内容") {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .longContent))
  }

  #Preview("标签详情 · 深色模式") {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .dark))
  }

  #Preview("标签详情 · 辅助功能字号") {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .accessibility))
  }

  #Preview("标签详情 · 最大辅助功能字号") {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .accessibilityMax))
  }

  #Preview("标签详情 · 窄宽度大字号", traits: .fixedLayout(width: 320, height: 874)) {
    TagDetailPreview(fixture: try! TagDetailPreviewFixture(scenario: .compactAccessibility))
  }
#endif
