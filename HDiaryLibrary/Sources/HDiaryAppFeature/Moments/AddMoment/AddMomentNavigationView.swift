//
//  AddMomentNavigationView.swift
//  HDiary
//
//  Created by tigerguo on 2023/10/28.
//

#if os(iOS)

import HDiaryConstants
import HDiaryIAP
import HDiaryModel
import SwiftData
import SwiftUI
#if canImport(JournalingSuggestions)
  @preconcurrency import JournalingSuggestions
#endif

enum AddMomentPresentation: Identifiable, Equatable, Hashable {
  case presentRecordSubscriptionView
  case presentRecordSubscriptionPromotionView
  case presentAddMomentView

  var id: Self { self }

  static func resolve(
    hasFeatureAccess: Bool,
    hasShownPromotion: Bool,
    currentMomentCount: Int,
    freeRecordNumber: Int
  ) -> Self {
    if hasFeatureAccess {
      return .presentAddMomentView
    }

    if !hasShownPromotion {
      return .presentRecordSubscriptionPromotionView
    }

    if currentMomentCount >= freeRecordNumber {
      return .presentRecordSubscriptionView
    }

    return .presentAddMomentView
  }
}

@MainActor
struct AddMomentNavigationView: View {
  enum Origin: CaseIterable, Sendable, Hashable, Identifiable {
    case empty
    case fromSuggestion

    var id: Self {
      self
    }
  }

  private enum SuggestionState {
    case noNeedToShow
    case needShow
    case convertingSuggestion
    case suggestedMoment(Moment)

    var isNeedShow: Bool {
      switch self {
      case .needShow:
        return true
      case .noNeedToShow, .suggestedMoment, .convertingSuggestion:
        return false
      }
    }
  }

  @Environment(UserPreferences.self) private var userPreferences
  @Environment(MomentCloudStateManager.self) private var momentCloudStateManager
  @Environment(\.modelContext) private var modelContext
  @Environment(\.recordFeatureAccessAllowed) private var recordFeatureAccessAllowed

  @State private var suggestionState: SuggestionState
  @State private var presentState: AddMomentPresentation?
  @State private var createdMoment: Moment = Moment.create(timestamp: .now)

  private let currentMomentCount: Int

  init(origin: Origin, currentMomentCount: Int) {
    self.currentMomentCount = currentMomentCount
    if origin == .fromSuggestion {
      suggestionState = .needShow
    }
    else {
      suggestionState = .noNeedToShow
    }
  }

  var body: some View {
//    let _ = Self._printChanges()
    content
      .task(id: presentState) {
        onInit()
      }
  }

  private func onInit() {
    #if DEBUG
      if userPreferences.bypassIPRestriction {
        Log.iap.info("Bypass IP restriction")
        presentState = .presentAddMomentView
        return
      }
    #endif

    let nextState = AddMomentPresentation.resolve(
      hasFeatureAccess: recordFeatureAccessAllowed,
      hasShownPromotion: userPreferences.hasShownRecordPromotionView,
      currentMomentCount: currentMomentCount,
      freeRecordNumber: AppConstants.IAP.freeRecordNumber
    )

    presentState = nextState

    switch nextState {
    case .presentRecordSubscriptionView:
      Log.iap.info("Show need subscribe view")
    case .presentRecordSubscriptionPromotionView:
      Log.iap.info("Show RecordSubscriptionPromotionView")
    case .presentAddMomentView:
      Log.iap.log("add moment")
    }
  }

  @ViewBuilder
  private var content: some View {
    switch presentState {
    case .presentAddMomentView:
      addMomentEntryView

    case .presentRecordSubscriptionPromotionView:
      RecordSubscriptionPromotionView(currentMomentCount: currentMomentCount) {
        presentState = .presentAddMomentView
      }

    case .presentRecordSubscriptionView:
      RecordSubscriptionView()
    case .none:
      EmptyView()
    }
  }

  @ViewBuilder
  private var addMomentEntryView: some View {
    switch suggestionState {
    case .noNeedToShow:
      addMomentView(with: createdMoment)
    case .convertingSuggestion:
      ProgressView {
        Text(DiaryStringKey.Moment.Suggestion.processingSuggestionLabel)
      }
      .progressViewStyle(.circular)
    case .needShow:
      #if canImport(JournalingSuggestions)
        if #available(iOS 17.2, *) {
          addMomentView(with: createdMoment)
            .journalingSuggestionsPicker(isPresented: .init(get: {
              suggestionState.isNeedShow
            }, set: { showing in
              Log.common.info("Journaling suggestion picker is showing: \(showing)")
              if !showing {
                suggestionState = .noNeedToShow
              }
            })) { suggestion in
              Log.common.info("Journaling suggestion selected: \(suggestion.title)")
              suggestionState = .convertingSuggestion
              let suggestedMoment = await MomentSuggestionUtil.momentFrom(suggestion: suggestion)
              suggestionState = .suggestedMoment(suggestedMoment)
            }
        }
        else {
          JournalSuggestionNotAvailableView()
        }
      #else
        JournalSuggestionNotAvailableView()
      #endif

    case .suggestedMoment(let suggestedMoment):
      addMomentView(with: suggestedMoment)
    }
  }

  @ViewBuilder
  func addMomentView(with addedMoment: Moment) -> some View {
    NavigationStack {
      AddMomentView(moment: addedMoment) { moment in
        Log.data.log("moment \(String(describing: moment.id)) added")
        withAnimation {
          modelContext.insert(moment)
        }
        momentCloudStateManager.addMomentToSync(moment)
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct JournalSuggestionNotAvailableView: View {
  // If put JournalSuggestionNotAvailableView in the AddMomentNavigationView, when presenting a photo picker, the `dismiss` would change, causing the AddMomentNavigationView to re-render, which would cause the moment data lose. So we put it here.
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      SuggestionUnavailableView()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel) {
              dismiss()
            } label: {
              Text(DiaryStringKey.Common.cancel)
            }
          }
        }
    }
  }
}

#if DEBUG
  #Preview { @MainActor in
    AddMomentNavigationView(origin: .empty, currentMomentCount: 20)
      .previewEnvironment()
  }
#endif

#endif
