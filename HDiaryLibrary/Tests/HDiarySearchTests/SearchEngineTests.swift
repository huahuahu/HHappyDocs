#if os(iOS)

  @testable import HDiaryModel
  @testable import HDiarySearch
  import Atomics
  import SwiftData
  import XCTest

  final class SearchEngineTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      return try ModelContainer(for: Schema.hDiaryScheme, configurations: [configuration])
    }

    func testSearchMomentMatchesTitleAndContent() async throws {
      let container = try makeContainer()
      let context = ModelContext(container)

      let titleMatch = Moment.create(timestamp: Date(timeIntervalSince1970: 2))
      titleMatch.updateTitle("needle title")
      titleMatch.updateContent("body")

      let contentMatch = Moment.create(timestamp: Date(timeIntervalSince1970: 1))
      contentMatch.updateTitle("title")
      contentMatch.updateContent("needle body")

      let nonMatch = Moment.create(timestamp: Date(timeIntervalSince1970: 3))
      nonMatch.updateTitle("title")
      nonMatch.updateContent("body")

      context.insert(titleMatch)
      context.insert(contentMatch)
      context.insert(nonMatch)
      try context.save()

      let engine = SearchEngine(modelContainer: container)
      let results = try await engine.searchMoment(
        for: "needle",
        isCancelled: ManagedAtomic<Bool>(false)
      )

      XCTAssertEqual(results.map(\.uuid), [titleMatch.uuid, contentMatch.uuid])
    }

    func testSearchMomentThrowsCancellationBeforeFetch() async throws {
      let container = try makeContainer()
      let engine = SearchEngine(modelContainer: container)
      let isCancelled = ManagedAtomic<Bool>(true)

      do {
        _ = try await engine.searchMoment(for: "needle", isCancelled: isCancelled)
        XCTFail("Expected CancellationError")
      }
      catch is CancellationError {
        XCTAssertTrue(true)
      }
    }
  }

#endif
