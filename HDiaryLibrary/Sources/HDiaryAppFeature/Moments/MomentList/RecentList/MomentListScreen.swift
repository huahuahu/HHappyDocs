//
//  MomentListScreen.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import Observation
import SwiftData
import SwiftUI

@MainActor
struct MomentListScreen: View {
  @Environment(\.calendar) private var calendar
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Query(filter: #Predicate<Moment> { !$0.markedAsDelete }, sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]) private var moments: [Moment]

  @State private var momentGroups: [InstanceGroup<Moment>] = []
  @Namespace private var addMomentTransitionNamespace
  private let addMomentSourceID = "add-moment"

  private struct AddMomentRequest: Identifiable {
    let origin: AddMomentNavigationView.Origin
    let usesZoom: Bool
    var id: AddMomentNavigationView.Origin { origin }
  }

  @State private var addMomentRequest: AddMomentRequest?
  let model: RecentMomentListModel.Model
  private let referenceDate: Date?
  private let initiallyExpanded: Bool
//    @State private var recentMomentListModel = RecentMomentListModel()

  init(
    model: RecentMomentListModel.Model = .showAllMoment,
    referenceDate: Date? = nil,
    initiallyExpanded: Bool = false
  ) {
    self.model = model
    self.referenceDate = referenceDate
    self.initiallyExpanded = initiallyExpanded
    //        self._moments = Query(
    switch model {
    case .showAllMoment:
      _moments = Query(filter: #Predicate { !$0.markedAsDelete }, sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)])
    case .showRecentMoment(let minDate, _):
      _moments = Query(
        filter: #Predicate<Moment> { $0.timestamp >= minDate && !$0.markedAsDelete },
        sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]
      )
    case .showRecentAsInitial(minDate: let minDate):
      _moments = Query(
        filter: #Predicate<Moment> { $0.timestamp >= minDate && !$0.markedAsDelete },
        sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]
      )
    }
  }

  var body: some View {
    List {
      ForEach(InstanceGrouper().group(moments, relative: referenceDate ?? .now, calendar: calendar)) { momentGroup in
        SectionView(momentGroup: momentGroup, initiallyExpanded: initiallyExpanded)
      }
      if case .showRecentMoment = model {
        RecentSection(moreMomentCount: currentMomentCount - moments.count)
      }
      if case .showRecentAsInitial = model {
        ProgressView()
      }
    }
    .scrollIndicatorsFlash(onAppear: true)
    .scrollIndicatorsFlash(trigger: moments.count)
    .hDiaryNavigator()
    .toolbar {
      toolBarContent
    }
    .sheet(item: $addMomentRequest, content: { request in
      // Sample the transition when opening so accessibility changes cannot replace
      // the sheet's view identity (and its unsaved Moment) during editing.
      if request.usesZoom {
        AddMomentNavigationView(origin: request.origin, currentMomentCount: currentMomentCount)
          .navigationTransition(.zoom(sourceID: addMomentSourceID, in: addMomentTransitionNamespace))
      }
      else {
        AddMomentNavigationView(origin: request.origin, currentMomentCount: currentMomentCount)
      }
    })
  }

  private var currentMomentCount: Int {
    switch model {
    case .showAllMoment:
      return moments.count
    case .showRecentMoment(_, let allMomentCount):
      return allMomentCount
    case .showRecentAsInitial:
      return moments.count
    }
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      addMomentMenu
        .matchedTransitionSource(id: addMomentSourceID, in: addMomentTransitionNamespace)
    }
  }

  private var addMomentMenu: some View {
    // The persistent toolbar control is the source, never a transient menu item.
    AddMomentMenu {
      presentAddMoment(from: .empty)
    } addMomentFromSuggestion: {
      presentAddMoment(from: .fromSuggestion)
    }
  }

  private func presentAddMoment(from origin: AddMomentNavigationView.Origin) {
    addMomentRequest = AddMomentRequest(origin: origin, usesZoom: !reduceMotion)
  }
}

#endif
