//
//  SearchViewModel.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//
import Atomics
import Foundation
import HDiaryConstants
import HDiaryModel
import Observation
import SwiftData

@MainActor
@Observable class SearchViewModel {
  var queryText = ""
  private enum Constants {
    static let throttleDurationInMs: UInt64 = 250
  }

  enum State {
    case idle
    case recommend(moments: [Moment])
    case searching(queryText: String)
    case searchSucceed(moments: [Moment])
    case searchError(error: Error)
  }

  private var searchTask: Task<Void, Never>?
  private(set) var state: State = .idle

  private let container: ModelContainer
  private let recommendEngine: SearchRecommendEngine
  private let searchEngine: SearchEngine

  init() {
    self.container = HDiaryContainer.getCurrentContainer()
    self.recommendEngine = SearchRecommendEngine(modelContainer: container)
    self.searchEngine = SearchEngine(modelContainer: container)
  }

  func reset() {
    state = .idle
    startRecommend()
  }

  func startRecommend() {
    Task {
      Log.search.info("Start Recommend")
      // Make sure getRecommendedMoment not running in main thread
      // https://developer.apple.com/documentation/Xcode/improving-app-responsiveness#Avoid-hangs-by-keeping-the-main-thread-free-from-non-UI-work
      let recommendedMoments = await Task.detached {
        await self.recommendEngine.getRecommendedMoment()
      }.value

      if self.queryText.isEmpty {
        self.state = .recommend(moments: recommendedMoments)
      }
    }
  }

  func search() async {
    searchTask?.cancel()
    guard !queryText.isEmpty else {
      reset()
      Log.search.info("Query text is empty, reset")
      return
    }
    Log.search.info("Searching for: \(self.queryText)")

    let query = self.queryText
    state = .searching(queryText: query)

    searchTask = Task {
      let isCancelled = ManagedAtomic<Bool>(false)
      await withTaskCancellationHandler {
        do {
          try await Task.sleep(nanoseconds: Constants.throttleDurationInMs * NSEC_PER_MSEC)
        }
        catch {
          Log.search.debug("Search cancelled before actual search for \(query)")
          return
        }

        let clock = SuspendingClock()
        let searchStartTime = clock.now

        do {
          Log.search.info("Search actual logic started for \(query)")

          let matchedMoment = try await Task.detached {
            try await self.searchEngine.searchMoment(for: query, isCancelled: isCancelled)
          }.value

          let searchEndTime = clock.now

          let searchDuration = searchStartTime.duration(to: searchEndTime)
          try Task.checkCancellation()

          state = .searchSucceed(moments: matchedMoment)
          Log.search.info("Search finished  after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public) for \(query), result count: \(matchedMoment.count, privacy: .public)")
        }
        catch {
          let searchEndTime = clock.now
          let searchDuration = searchStartTime.duration(to: searchEndTime)
          if error is CancellationError {
            Log.search.info("Search cancelled for \(query) after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public)")
          }
          else if query != self.queryText {
            Log.search.info("Search cancelled because query changed for \(query) after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public)")
          }
          else {
            Log.search.error("Failed to fetch moments for \(query): \(error) after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public)")
            state = .searchError(error: error)
          }
        }

      } onCancel: {
        isCancelled.store(true, ordering: .relaxed)
      }
    }
  }
}
