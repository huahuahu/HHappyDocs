#if os(macOS)

  import XCTest
  @testable import HDiarySearch

  @available(macOS 14.0, *)
  final class MacOSPublicAPITests: XCTestCase {
    @MainActor
    func testSearchViewModelAPIIsAvailableOnMacOS() {
      _ = SearchViewModel.State.idle
      let makeViewModel: @MainActor () -> SearchViewModel = SearchViewModel.init
      _ = makeViewModel
    }
  }

#endif
