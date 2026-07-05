//
//  AllMomentListScreen.swift
//  HDiary
//
//  Created by tigerguo on 2025/5/4.
//

import HDiaryConstants
import HDiaryModel
import Observation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
struct AllMomentListScreen: View {
  @Environment(\.modelContext) private var modelContext

  @State private var momentGroups: [InstanceGroup<Moment>] = []
  @State private var selectedFilter: MomentFilter?
  @State private var moments: [Moment] = []

  var body: some View {
    List {
      ForEach(InstanceGrouper().group(filteredMoments, relative: .now)) { momentGroup in
        MomentListScreen.SectionView(momentGroup: momentGroup)
      }
    }
    .scrollIndicatorsFlash(onAppear: true)
    .scrollIndicatorsFlash(trigger: filteredMoments.count)
    .hDiaryNavigator()
    .toolbar {
      toolBarContent
    }
    .onChange(of: moments.count) { _, _ in
      Log.common.info("moments count change to \(moments.count)")
      WidgetCenter.shared.reloadAllTimelines()
    }
    .task {
      fetchMoments()
    }
    .navigationTitle(Text(DiaryStringKey.Moment.allMomentsTitle))
    .navigationBarTitleDisplayMode(.inline)
  }

  private var filteredMoments: [Moment] {
    if let selectedFilter {
      moments.filter { selectedFilter.isMatched(moment: $0) }.filter { $0.markedAsDelete == false }
    }
    else {
      moments.filter { $0.markedAsDelete == false }
    }
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    #if os(iOS)
      ToolbarItem(placement: .topBarTrailing) {
        MomentFilterMenu(selectedFilter: $selectedFilter)
      }
    #endif
  }

  private func fetchMoments() {
    let fetchDescriptor = FetchDescriptor<Moment>(predicate: #Predicate { moment in
      moment.markedAsDelete == false
    }, sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
    do {
      moments = try modelContext.fetch(fetchDescriptor)
    }
    catch {
      Log.common.error("Failed to fetch moments: \(error)")
    }
  }
}

#if DEBUG
  @available(iOS 18, *)
  #Preview(traits: .modifier(SampleDataModifier())) {
    NavigationStack {
      AllMomentListScreen()
    }
    .previewEnvironment()
  }

#endif
