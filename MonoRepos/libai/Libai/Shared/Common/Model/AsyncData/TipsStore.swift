//
//  TipsStore.swift
//  Libai
//
//  Created by huahuahu on 2022/3/12.
//

import Combine
import Foundation

class TipsStore<T: Equatable>: ObservableObject {
  private var updateTipsTask: Task<Void, Never>?
  @Published private(set) var tips: String? {
    didSet {
      dataLog("tips become \(String(describing: tips))")
    }
  }

  private var subscriptions = Set<AnyCancellable>()
  private var tempSubscriptions = Set<AnyCancellable>()
  @Published private var dataSyncState: DataSyncState<T> = .initial

  func updated(_ publisher: AnyPublisher<DataSyncState<T>, Never>) {
    dataLog("update begin")
    subscriptions.removeAll()
    tempSubscriptions.removeAll()

    publisher
      .map { state -> DataSyncState<T> in
        dataLog("new State \(state.debugText)")
        return state
      }
      .sink { state in
        self.onNewState(state)
//              self.dataSyncState = state
      }
      .store(in: &subscriptions)
  }

  private func onNewState(_ newState: DataSyncState<T>) {
    if dataSyncState.isSyncWithNet, tips != nil {
      dataLog("upate tips when loading start and previous tips is not nil")
      tips = newState.tipsInView
    }
    dataSyncState = newState

    if newState.isLoading {
      updateTipsTask?.cancel()
      Timer
        .publish(every: 2, on: .main, in: .default)
        .autoconnect()
        .sink { _ in
          dataLog("check state \(self.dataSyncState.tipsInView)")
          self.tips = self.dataSyncState.tipsInView
        }
        .store(in: &tempSubscriptions)
    }
    else if newState.isSyncWithNet {
      tempSubscriptions.removeAll()
      if newState.netError != nil {
        dataLog("sync finish with error, update tips and remove timer")
        tips = newState.tipsInView
      }
      if newState.netError == nil {
        dataLog("sync finish with out error, remove timer")
        if tips != nil {
          dataLog("previous tips is not nil, update")
          tips = newState.tipsInView
        }
        else {
          dataLog("previous tips is nil, no tips")
        }
        updateTipsTask = Task {
          do {
            try await Task.sleep(nanoseconds: 2.inNanoSeconds)
            await MainActor.run {
              dataLog("set to nil after two seconds")
              self.tips = nil
            }
          }
          catch {
            dataLog("cancelled")
          }
        }
      }
    }
  }
}
