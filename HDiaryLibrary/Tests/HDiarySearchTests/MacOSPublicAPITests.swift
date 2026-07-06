#if os(macOS)

  import SwiftData
  import Testing
  import HDiaryModel
  import HDiarySearch

  struct MacOSPublicAPITests {
    @Test
    @MainActor
    @available(macOS 14.0, *)
    func searchViewModelAPIIsAvailableOnMacOS() throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      let container = try ModelContainer(for: schema, configurations: [configuration])

      let viewModel = SearchViewModel(modelContainer: container)

      #expect(viewModel.queryText.isEmpty)
      if case .idle = viewModel.state {
      }
      else {
        Issue.record("Expected a new SearchViewModel to start idle.")
      }
    }
  }

#endif
