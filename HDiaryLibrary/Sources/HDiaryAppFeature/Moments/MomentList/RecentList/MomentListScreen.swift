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
import WidgetKit

@MainActor
struct MomentListScreen: View {
  @Environment(UserPreferences.self) private var userPreferences: UserPreferences
  @Environment(MomentCloudStateManager.self) private var momentCloudStateManager
  @Environment(\.modelContext) private var modelContext

  @Query(filter: #Predicate<Moment> { !$0.markedAsDelete }, sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]) private var moments: [Moment]

  @State private var momentGroups: [InstanceGroup<Moment>] = []
  @State private var addMomentOrigin: AddMomentNavigationView.Origin?
  let model: RecentMomentListModel.Model
//    @State private var recentMomentListModel = RecentMomentListModel()

  init(model: RecentMomentListModel.Model = .showAllMoment) {
    self.model = model
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
      ForEach(InstanceGrouper().group(moments, relative: .now)) { momentGroup in
        SectionView(momentGroup: momentGroup)
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
    .sheet(item: $addMomentOrigin, content: { origin in
      AddMomentNavigationView(origin: origin, currentMomentCount: currentMomentCount)
    })
    .onAppear {
      if UserPreferences.shared.swiftDataContainerType != .iCloud {
        momentCloudStateManager.shouldSync = false
      }
      WidgetCenter.shared.reloadAllTimelines()
    }
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
      AddMomentMenu {
        addMomentOrigin = .empty
      } addMomentFromSuggestion: {
        addMomentOrigin = .fromSuggestion
      }
    }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      MomentListScreen()
    }
    .previewEnvironment()
    .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
  }

#endif

#endif
