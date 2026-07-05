//
//  BaseTabView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

import HDiaryConstants
import HDiaryModel
import HLocalization
import Observation
import SwiftData
import SwiftUI

@MainActor
struct BaseTabView: View {
  private static var firstMomentQuery = {
    var descriptor = FetchDescriptor<Moment>(predicate: #Predicate<Moment> { !$0.markedAsDelete })
    descriptor.fetchLimit = 1
    return descriptor
  }()

  @Environment(\.modelContext) private var modelContext
  @Environment(\.undoManager) private var undoManager
  @Environment(HDiaryRoute.self) private var appRoute
  @Environment(UserPreferences.self) private var userPreferences

  @Query private var moments: [Moment]
  @State private var hasPerformedStartupTask = false

  init() {
    _moments = Query(Self.firstMomentQuery)
  }

  @State private var searchViewModel = SearchViewModel()
  var body: some View {
    @Bindable var appRoute = appRoute
    TabView(selection: $appRoute.selectedTab) {
      contentView
        .tag(HDiaryTab.content)
      libraryView
        .tag(HDiaryTab.library)
      settingView
        .tag(HDiaryTab.setting)
    }
    .sensoryFeedback(.selection, trigger: appRoute.selectedTab)
    .onAppear {
      guard !hasPerformedStartupTask else {
        return
      }
      hasPerformedStartupTask = true
      Log.common.info("Performing startup task")
      migrationDB()
      updateMediaInfo()
      cleanUpData()
      modelContext.undoManager = undoManager
    }
  }

  @ViewBuilder
  private var contentView: some View {
    MomentTab(isSelected: appRoute.selectedTab == .content)
      .environment(searchViewModel)
      .if(shouldSupportSearch, transform: { content in
        content
          .searchable(searchViewModel: $searchViewModel)
      })
      .tabItem {
        Label {
          Text(DiaryStringKey.moments)
        } icon: {
          Image(systemName: "list.dash")
        }
      }
  }

  private var shouldSupportSearch: Bool {
    #if DEBUG
      guard userPreferences.supportSearch else {
        return false
      }
    #endif
    return !moments.isEmpty
  }

  @ViewBuilder
  private var settingView: some View {
    SettingsView(isSelected: .init(get: {
      appRoute.selectedTab == .setting
    }, set: { _ in

    })).tabItem {
      Label(HLocalizedString.setting, systemImage: "gear")
    }
  }

  @ViewBuilder
  private var libraryView: some View {
    LibraryView(isSelected: .init(get: {
      appRoute.selectedTab == .library
    }, set: { _ in

    })).tabItem {
      Label(
        title: { Text(DiaryStringKey.libraryTabItemLabel) },
        icon: { Image(systemName: "cube.box") }
      )
    }
  }

  private func migrationDB() {
    do {
      let legacyImages = try modelContext.fetch(FetchDescriptor<HappyImage>())
      for image in legacyImages {
        if image.moment != nil {
          image.updateThumbnail()
          let mediaItem = MediaItem(image)
          mediaItem.moment = image.moment
          modelContext.insert(mediaItem)
          modelContext.delete(image)
          Log.DB.migration.info("update thumbnail for image \(image.uuid)")
        }
        else {
          modelContext.delete(image)
          Log.DB.migration.info("delete image  \(image.uuid) because no moments")
        }
      }
      try modelContext.save()
      Log.DB.migration.info("legacy image migration successed")
    }
    catch {
      Log.DB.migration.error("Migrate legacy image fail \(error)")
    }
  }

  private func updateMediaInfo() {
    do {
      try modelContext.enumerate(FetchDescriptor<MediaItem>(), batchSize: 10, allowEscapingMutations: true) { mediaItem in
        if mediaItem.storageSize == nil {
          mediaItem.updateStorageSizeIfNeeded()
          Log.DB.migration.info("media item \(mediaItem.uuid) update storage size successed")
        }
      }
    }
    catch {
      Log.DB.migration.error("media item update storage size fail \(error)")
    }
  }

  private func cleanUpData() {
    // 1. Clean up legacy images
    do {
      Log.data.info("Start to clean up data")
      var deletedMediaItems: [UUID] = []
      var validMediaItems: [UUID] = []
      try modelContext.enumerate(FetchDescriptor<MediaItem>(), batchSize: 5) { mediaItem in
        if mediaItem.moment == nil {
          deletedMediaItems.append(mediaItem.uuid)
          Log.data.info("delete media item \(mediaItem.uuid, privacy: .public)")
          modelContext.delete(mediaItem)
        }
        else {
          validMediaItems.append(mediaItem.uuid)
        }
      }
      try modelContext.save()
      Log.data.info("Finish to clean up data, deleted media items: \(deletedMediaItems, privacy: .public), valid media items: \(validMediaItems.count, privacy: .public)")
    }
    catch {
      Log.data.error("Failed to clean up data: \(error)")
    }

    // 2. Clean up deleted moments
    do {
      // Define a timestamp, if markedAsDeleleteTime is older than this timestamp, delete the moment
      let deleteTimeThreshold = Date(timeIntervalSinceNow: -60 * 60 * 24 * 30) // 30 days
//      let deleteTimeThreshold = Date.now // 30 days

      Log.data.info("Start to clean up deleted moments")
      let momentsCountBeforeDeletion = try modelContext.fetchCount(FetchDescriptor<Moment>())
      let predicate = #Predicate<Moment> {
        if $0.markedAsDelete {
          if let markedAsDeleteDate = $0.markedAsDeleteDate {
            return markedAsDeleteDate < deleteTimeThreshold
          }
          else {
            return false
          }
        }
        else {
          return false
        }
      }
      try modelContext.delete(model: Moment.self, where: predicate)
      try modelContext.save()
      let momentsCountAfterDeletion = try modelContext.fetchCount(FetchDescriptor<Moment>())
      Log.data.info("Finish to clean up deleted moments, deleted moments count: \(momentsCountBeforeDeletion - momentsCountAfterDeletion, privacy: .public)")
    }
    catch {
      Log.data.error("Failed to clean up deleted moments: \(error)")
    }
  }
}
