//
//  RecentMomentListModel.swift
//  HDiary
//
//  Created by tigerguo on 2025/5/4.
//

#if os(iOS)

import Combine
import Foundation
import HDiaryConstants
import HDiaryModel
import Observation
import SwiftData

@Observable @MainActor
final class RecentMomentListModel {
  enum Constants {
    // The threshold for showing all moments. If the number of moments is greater than this value, only show recent moments.
    static let showAllMomentThreshold: Int = 90
  }

  var modelContext: ModelContext?
  var mode: Model = .showRecentAsInitial(minDate: Calendar.current.startOfPreviousMonthOrJanuaryFirst(from: Date()) ?? Date().addingTimeInterval(-60 * 60 * 24 * 60))

  private var cancellables = Set<AnyCancellable>()

  private var hasUpdatedWithModelContext = false
  init() {
    NotificationCenter.default.publisher(for: ModelContext.didSave)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.onSave()
      }
      .store(in: &cancellables)
  }

  func updateMode(modelContext: ModelContext) {
    self.modelContext = modelContext
    if hasUpdatedWithModelContext {
      return
    }
    hasUpdatedWithModelContext = true
    //        self.modelContext = modelContext
    innerUpdate(with: modelContext)
  }

  private func innerUpdate(with modelContext: ModelContext) {
    var allMomentCount: Int?
    do {
      allMomentCount = try modelContext.fetchCount(FetchDescriptor<Moment>(predicate: #Predicate<Moment> { !$0.markedAsDelete }))
    }
    catch {
      Log.data.error("Failed to get all moment count")
    }

    guard let allMomentCount else {
      self.mode = .showAllMoment
      return
    }

    Log.data.info("all moment count is \(allMomentCount)")

    if allMomentCount < Constants.showAllMomentThreshold {
      self.mode = .showAllMoment
    }
    else if let minDate = Calendar.current.startOfPreviousMonthOrJanuaryFirst(from: Date()) {
      self.mode = .showRecentMoment(minDate: minDate, allMomentCount: allMomentCount)
    }
    else {
      self.mode = .showAllMoment
    }
  }

  private func onSave() {
    Log.data.info("ModelContext saved, re-calculate moment count")
    if let modelContext {
      innerUpdate(with: modelContext)
    }
//        do {
//          tempAllMomentCount = try modelContext?.fetchCount(FetchDescriptor<Moment>())
//        }
//        catch {
//          Log.data.error("Failed to get all moment count")
//        }
//        if let tempAllMomentCount, tempAllMomentCount != allMomentCount {
//            allMomentCount = tempAllMomentCount
//        }
  }

  enum Model: Equatable {
    case showRecentAsInitial(minDate: Date)
    case showAllMoment
    case showRecentMoment(minDate: Date, allMomentCount: Int)
  }
}

#endif
