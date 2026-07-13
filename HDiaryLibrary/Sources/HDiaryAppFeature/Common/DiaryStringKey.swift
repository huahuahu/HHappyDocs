//
//  DiaryStringKey.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import Foundation
import SwiftUI

private final class BundleLocation {}

private extension LocalizedStringResource.BundleDescription {
  nonisolated static var module: Self {
    Self.forClass(BundleLocation.self)
  }
}

public enum DiaryStringKey {
  public static let happyListNavigationTitle = LocalizedStringResource("happyListNavigationTitle", defaultValue: "Moments", bundle: .module, comment: "happyListNavigationTitle")

  public static let dismiss = LocalizedStringResource("navigation.button.dismiss", defaultValue: "Dismiss", bundle: .module, comment: "When presenting a view, tap this button to dismiss")

  public static let confirm = LocalizedStringResource("navigation.button.confirm", defaultValue: "Confirm", bundle: .module, comment: "Used as navigation bar's confirm button's title")

  public static let addImage = LocalizedStringResource("common.addImage", defaultValue: "Add Image", bundle: .module, comment: "Use as text for adding image")

  public static let edit = LocalizedStringResource("commmon.edit", defaultValue: "Edit", bundle: .module, comment: "For common edit button")

  public static let add = LocalizedStringResource("commmon.add", defaultValue: "Add", bundle: .module, comment: "For common add button")

  public static let crop = LocalizedStringResource("commmon.crop", defaultValue: "Crop", bundle: .module, comment: "For common crop button")

  public static let total = LocalizedStringResource("commmon.total", defaultValue: "total", bundle: .module, comment: "For common total")

  public static let rating = LocalizedStringResource("commmon.rating", defaultValue: "rating", bundle: .module, comment: "For common rating")
  public static let unrated = LocalizedStringResource("commmon.unrated", defaultValue: "unrated", bundle: .module, comment: "For common unrated")
  public static let count = LocalizedStringResource("commmon.count", defaultValue: "count", bundle: .module, comment: "For common count")
  public static func textForRating(_ count: Int) -> LocalizedStringResource {
    LocalizedStringResource("\(count) star", bundle: .module, comment: "Show xx start rating")
  }

  // MARK: - Moment

  public static let moments = LocalizedStringResource("happyListTabItemTitle", bundle: .module)

  public static let addMomentViewTitle = LocalizedStringResource("addMomentViewTitle", defaultValue: "Add Moment", bundle: .module, comment: "When adding moment, a view is presented, this is used as the whole view's tile")

  public static let editMomentViewTitle = LocalizedStringResource("editMomentViewTitle", defaultValue: "Edit Moment", bundle: .module, comment: "When editing moment, a view is presented, this is used as the whole view's tile")

  public static let addMomentViewDoneButton = LocalizedStringResource("addMoment.navigation.button.finish", defaultValue: "Add", bundle: .module, comment: "When adding moment, after tapping this button, add to database")

  public static let addMomentTitleSection = LocalizedStringResource("addMomentTitleSection", defaultValue: "Title", bundle: .module, comment: "When adding moment, this is used as section header to indicate user to add title")

  public static let addMomentTitleSectionPlaceHolder = LocalizedStringResource("addMomentTitleSectionPlaceHolder", defaultValue: "Title here ...", bundle: .module, comment: "When adding moment, this is used as place holder to indicate user to add title ")

  public static let addMomentContentSection = LocalizedStringResource("addMomentContentSection", defaultValue: "Content", bundle: .module, comment: "When adding moment, this is used as section header to indicate user to add conent")

  public static let addMomentContentSectionPlaceHolder = LocalizedStringResource("addMomentContentSectionPlaceHolder", defaultValue: "Content here ...", bundle: .module, comment: "When adding moment, this is used as place holder to indicate user to add conent")

  public static let addMomentTimeStampSectionHeader = LocalizedStringResource("addMomentTimeStampSectionHeader", defaultValue: "Timestamp", bundle: .module, comment: "When adding moment, this is used as section header to indicate user to select timestamp")

  public static let addMomentTimeStampLabel = LocalizedStringResource("addMomentTimeStampLabel", defaultValue: "Happen at", bundle: .module, comment: "When adding moment, this is used as date picker's label")

  public static let momentDetailViewNavigationTitle = LocalizedStringResource("moment.detail.navigation.title", defaultValue: "Moment Detail", bundle: .module, comment: "When adding moment, a view is presented, this is used as navigation bar")

  public static let momentEditViewMediaSectionHeaderLabel = LocalizedStringResource("moment.detail.section.media.header", defaultValue: "Media", bundle: .module, comment: "When editing moment, section header for editing media")

  public static let momentEditViewRatingSectionHeaderLabel = LocalizedStringResource("moment.detail.section.rating.header", defaultValue: "Rating", bundle: .module, comment: "When editing moment, section header for editing rating")

  public static func momentLabelWithNumber(_ count: Int) -> LocalizedStringResource {
    LocalizedStringResource("\(count) moment", bundle: .module, comment: "Show moment count")
  }

  public enum Moment {
    enum Filter {
      public static let weekend = LocalizedStringResource("moment.filter.weekend", defaultValue: "Weekend", bundle: .module, comment: "Label for weekend filter")
      public static let hasMedia = LocalizedStringResource("moment.filter.hasMedia", defaultValue: "Has media", bundle: .module, comment: "Label for the filter 'has media'")
      public static let all = LocalizedStringResource("moment.filter.all", defaultValue: "All", bundle: .module, comment: "Label for non filter, i.e. not any filter")

      public static let filter = LocalizedStringResource("moment.filter", defaultValue: "Filter", bundle: .module, comment: "Label for the context menu to select filter")
    }

    enum Add {
      public static let newFromEmpty = LocalizedStringResource("moment.add.fromEmpty", defaultValue: "Create Empty Moment", bundle: .module, comment: "Label for add new moment from plain template")
      public static let newFromSuggestion = LocalizedStringResource("moment.add.fromSuggestion", defaultValue: "Create from Suggestion", bundle: .module, comment: "Label for add new moment from Journaling Suggestions")
      public static let suggestionUnavailableTitle = LocalizedStringResource("moment.add.suggestionUnavailableTitle", defaultValue: "Feature Unavailable", bundle: .module, comment: "Text shown when no suggestion available as title")
      public static let suggestionUnavailableDescription = LocalizedStringResource("moment.add.suggestionUnavailableDescription", defaultValue: "Journaling Suggestions is only available on iPhones running iOS 17.2 or later. Please update your device or use a compatible iPhone.", bundle: .module, comment: "Text shown when no suggestion available as description")
    }

    enum CloudSync {
      public static let syncingLabel = LocalizedStringResource("moment.cloudSync.syncing.label", defaultValue: "syncing", bundle: .module, comment: "Label for syncing icon")
      public static let syncingSheetTitle = LocalizedStringResource("moment.cloudSync.syncing.sheet.title", defaultValue: "Syncing to iCloud", bundle: .module, comment: "Text when user taps the sync button, this text is shown to user as title")
      public static let syncingSheetText = LocalizedStringResource("moment.cloudSync.syncing.sheet.text", defaultValue: "Please wait while your item is being uploaded to iCloud. This may take a moment.", bundle: .module, comment: "Text when user taps the sync button, this text is shown to user as description")
    }

    enum Suggestion {
      public nonisolated static func descriptionForVisiting(place: String) -> LocalizedStringResource {
        LocalizedStringResource(
          "moment.suggestion.description.forVisiting",
          defaultValue: "Visited \(place)",
          table: "Localizable",
          bundle: .module,
          comment: "Description for visiting a place, with place name"
        )
      }

      public nonisolated static func descriptionForListening(song: String) -> LocalizedStringResource {
        LocalizedStringResource(
          "moment.suggestion.description.forListening.onlySong",
          defaultValue: "Listened \(song)",
          table: "Localizable",
          bundle: .module,
          comment: "Description for listening a song, with song name"
        )
      }

      public nonisolated static func descriptionForListening(song: String, by artist: String) -> LocalizedStringResource {
        LocalizedStringResource(
          "moment.suggestion.description.forListening.songAndArtist",
          defaultValue: "Listened \(song) by \(artist)",
          table: "Localizable",
          bundle: .module,
          comment: "Description for listening a song, with song name and artist name"
        )
      }

      public nonisolated static func descriptionForListening(podcast episode: String, from show: String?) -> LocalizedStringResource {
        if let show {
          return LocalizedStringResource(
            "moment.suggestion.description.forListening.podcastEpisodeAndShow",
            defaultValue: "Listened podcast episode \(episode) from \(show)",
            table: "Localizable",
            bundle: .module,
            comment: "Description for listening a podcast episode, with episode name and show name"
          )
        }
        else {
          return LocalizedStringResource(
            "moment.suggestion.description.forListening.podcastEpisode",
            defaultValue: "Listened podcast episode  \(episode)",
            table: "Localizable",
            bundle: .module,
            comment: "Description for listening a podcast episode, with episode name"
          )
        }
      }

      public nonisolated static func descriptionForMotionActivity(stepCount: String, movementType: String) -> LocalizedStringResource {
        LocalizedStringResource(
          "moment.suggestion.description.forMotionActivity",
          defaultValue: "\(movementType) for \(stepCount) steps",
          table: "Localizable",
          bundle: .module,
          comment: "Description for motion activity, with movement type and step count"
        )
      }

      public nonisolated static let movementTypeRunningDescription = LocalizedStringResource("moment.suggestion.description.movementType.running", defaultValue: "Ran", bundle: .module, comment: "Description for running")
      public nonisolated static let movementTypeWalkingDescription = LocalizedStringResource("moment.suggestion.description.movementType.walking", defaultValue: "Walked", bundle: .module, comment: "Description for walking")
      public nonisolated static let movementTypeRunningWalkingDescription = LocalizedStringResource("moment.suggestion.description.movementType.runningWalking", defaultValue: "Mixed ran and walked", bundle: .module, comment: "Description for mixed running and walking movement")
      public nonisolated static let movementTypeUnknownDescription = LocalizedStringResource("moment.suggestion.description.movementType.unknown", defaultValue: "Completed", bundle: .module, comment: "Description for unknown activity type")

      public static let processingSuggestionLabel = LocalizedStringResource(
        "moment.suggestion.processing",
        defaultValue: "Processing...",
        bundle: .module,
        comment: "Label for processing suggestion after user select a suggestion"
      )
    }

    public static let moreRemainingMomentLabel = LocalizedStringResource(
      "moment.remaining",
      defaultValue: "More moments",
      table: "Localizable",
      bundle: .module,
      comment: "Text shown when there are more moments to load"
    )

    public static let allMomentsTitle = LocalizedStringResource(
      "moment.filter.allMoments.title",
      defaultValue: "All Moments",
      bundle: .module,
      comment: "Title for the screen that shows all moments"
    )
  }

  // MARK: - Library

  public static let libraryTabItemLabel = LocalizedStringResource("tab.library", defaultValue: "Library", bundle: .module, comment: "Used as tab item label for library")

  public static let tagEntryLabel = LocalizedStringResource("library.entry.tag.label", defaultValue: "Tag", bundle: .module, comment: "Used to indicate this is tag entry")

  public static let tagEditTitleSectionHeader = LocalizedStringResource("library.tag.edit.title.sectionHeader", defaultValue: "Title", bundle: .module, comment: "Used as section header to indicate this is abut tag's title")

  public static let tagEditTitlePlaceHolder = LocalizedStringResource("library.tag.edit.title.placeHolder", defaultValue: "Title here", bundle: .module, comment: "Used as place holder to indicate this is abut tag's title")

  public static let tagEditCommentSectionHeader = LocalizedStringResource("library.tag.edit.comment.sectionHeader", defaultValue: "Description", bundle: .module, comment: "Used as section header to indicate this is abut tag's comment")

  public static let tagEditCommentPlaceHolder = LocalizedStringResource("library.tag.edit.comment.placeHolder", defaultValue: "Description here...", bundle: .module, comment: "Used as place holder to indicate this is abut tag's comment")

  public static let tagEditNavigationButtonTitleAdd = LocalizedStringResource("library.tag.add.done", defaultValue: "Add", bundle: .module, comment: "Used as navigation bar button's title when adding tag")

  public static let tagAddNavigationTitle = LocalizedStringResource("library.tag.add.title", defaultValue: "Add tag", bundle: .module, comment: "Navigation title for the adding tag view")

  public static let tagEditNavigationTitle = LocalizedStringResource("library.tag.edit.title", defaultValue: "Edit tag", bundle: .module, comment: "Navigation title for the editing tag view")

  public static let tagEmptyViewLabel = LocalizedStringResource("library.tag.empty.label", defaultValue: "No Tag", bundle: .module, comment: "In empty view for no tag, used as label")

  public static let tagEmptyViewDescription = LocalizedStringResource("library.tag.empty.description", defaultValue: "New Tags you create will appear here.", bundle: .module, comment: "In empty view for no tag, used as description")

  public static let momentTagEditViewNavigationTitle = LocalizedStringResource("lib.moment.tag.edit.navigationBar.title", defaultValue: "Edit Tag", bundle: .module, comment: "When adding/removing tags for moment, used as navigation view's title")

  public static let momentTagEditViewEmptyString = LocalizedStringResource("moment.edit.tag.seletion", defaultValue: "Select tags from below", bundle: .module, comment: "When adding/removing tags for moment, used as empty string")

  public static let participantEntryLabel = LocalizedStringResource("library.entry.participant.label", defaultValue: "Participant", bundle: .module, comment: "Used to indicate this is Participant entry")

  public static let participantEmptyViewLabel = LocalizedStringResource("library.participant.empty.label", defaultValue: "No Participant", bundle: .module, comment: "In empty view for no participant, used as label")

  public static let participantEmptyViewDescription = LocalizedStringResource("library.participant.empty.description", defaultValue: "New Participant you create will appear here.", bundle: .module, comment: "In empty view for no participant, used as description")

  public static let momentParticipantEditViewNavigationTitle = LocalizedStringResource("lib.moment.participant.edit.navigationBar.title", defaultValue: "Edit Participant", bundle: .module, comment: "When adding/removing participant for moment, used as navigation view's title")

  public static let momentParticipantEditViewEmptyString = LocalizedStringResource("lib.moment.participant.edit.nothing", defaultValue: "Select participants from below", bundle: .module, comment: "When adding/removing participant for moment, used as empty string")

  public static let participantNickName = LocalizedStringResource("library.participant.nickName", defaultValue: "nick name", bundle: .module, comment: "Used when need show participant's nick name")

  public static let participantName = LocalizedStringResource("library.participant.name", defaultValue: "name", bundle: .module, comment: "Used when need show participant's name")

  public static let participantNote = LocalizedStringResource("library.participant.note", defaultValue: "note", bundle: .module, comment: "Used when need show participant's note")

  enum Participant {
    public static func messageWhenDeletingParticipant(with nickName: String) -> LocalizedStringResource {
      LocalizedStringResource(
        "participant.delete.message",
        defaultValue: "Are you sure you want to delete \(nickName)?",
        table: "Localizable",
        bundle: .module,
        comment: "Message shown to user when deleting a participant with given nick name"
      )
    }
  }

  // MARK: - Charts

  public static let chart = LocalizedStringResource("library.chart", defaultValue: "Chart", bundle: .module, comment: "Used for chart")

  public static let chartEntrySummary = LocalizedStringResource(
    "library.entry.chart.summary",
    defaultValue: "View record trends",
    bundle: .module,
    comment: "Summary shown on the chart library entry card"
  )

  public static let chartEntryByRating = LocalizedStringResource("library.chart.entry.byRating", defaultValue: "by rating", bundle: .module, comment: "entry for rating pie chart")
  public static let chartEntryByTag = LocalizedStringResource("library.chart.entry.byTag", defaultValue: "by tag", bundle: .module, comment: "entry for tag chart")
}

extension DiaryStringKey {
  enum Library {
    enum Chart {
      public static func timeRangeForLastDays(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource("last \(count) day", bundle: .module, comment: "last xxx days")
      }

      public static let customTimeRange = LocalizedStringResource("library.chart.timeRange.custome", defaultValue: "Custom", bundle: .module, comment: "text for custom time range")
      public static let startDate = LocalizedStringResource("library.chart.timeRange.start", defaultValue: "Start Date", bundle: .module, comment: "text for selecting start date")
      public static let endDate = LocalizedStringResource("library.chart.timeRange.end", defaultValue: "End Date", bundle: .module, comment: "text for selecting end date")
    }
  }
}

extension DiaryStringKey {
  enum Tag {
    public static func textForTotalTagCount(_ count: Int) -> LocalizedStringResource {
      LocalizedStringResource("\(count) tags in total.", bundle: .module, comment: "text for total tag count")
    }
  }
}

extension DiaryStringKey {
  enum Notification {
    static let cellLabel = LocalizedStringResource("notification.cell.label", defaultValue: "Daily Reminder", bundle: .module, comment: "cell label in settings for notification")
    static let notSetLabel = LocalizedStringResource("notification.cell.label.notset", defaultValue: "Off", bundle: .module, comment: "label for showing no reminder")

    static let reminderContentTitle = LocalizedStringResource("notification.content.title", defaultValue: "Daily Reminder", bundle: .module, comment: "daily reminder notification title")
    static let reminderContentBody = LocalizedStringResource("notification.content.body", defaultValue: "Record your happy moments today", bundle: .module, comment: "daily reminder notification body")
    static let dailyReminderEnableLabel = LocalizedStringResource("notification.detail.switch.label", defaultValue: "Enable Daily Reminder", bundle: .module, comment: "label for enable daily reminder")
    static let timePickerLabel = LocalizedStringResource("notification.timePicker.label", defaultValue: "Reminder Time", bundle: .module, comment: "label for select time")
    static let setFailMessage = LocalizedStringResource("notification.set.fail.label", defaultValue: "Failed to set daily reminder", bundle: .module, comment: "message for set daily reminder fail")

    static let noPermissionReminder = LocalizedStringResource(
      "notification.permission.noAuth.reminder",
      defaultValue: "please go to Settings > HDiary > Notifications and enable notifications.",
      bundle: .module,
      comment: "cell label in settings for notification"
    )
  }
}

extension DiaryStringKey {
  enum Common {
    enum Date {
      static let future = LocalizedStringResource("common.date.future", defaultValue: "Future", bundle: .module, comment: "show text for 'future'")
      static let today = LocalizedStringResource("common.date.today", defaultValue: "Today", bundle: .module, comment: "show text for 'today'")
      static let yesterday = LocalizedStringResource("common.date.yesterday", defaultValue: "Yesterday", bundle: .module, comment: "show text for 'yesterday'")
      static let recent7Days = LocalizedStringResource("common.date.recent7day", defaultValue: "Recent 7 Days", bundle: .module, comment: "show text for 'recent 7 days'")
      static let ungrouped = LocalizedStringResource("common.date.ungrouped", defaultValue: "Ungrouped", bundle: .module, comment: "show text for 'ungrouped'")
    }

    static let helpAndFeedback = LocalizedStringResource("common.helpAndFeedback", defaultValue: "Help & Feedback", table: "Localizable", comment: "Used as help & feedback title")
    static let clear = LocalizedStringResource("common.clear", defaultValue: "Clear", table: "Localizable", comment: "Clear")
    static let clearing = LocalizedStringResource("common.clearing", defaultValue: "Clearing...", table: "Localizable", comment: "label shown to user for clear in progress")
    static let delete = LocalizedStringResource("common.delete", defaultValue: "Delete", table: "Localizable", comment: "common Delete")
    static let confirmDelete = LocalizedStringResource("common.delete.confirm", defaultValue: "Confirm Delete", table: "Localizable", comment: "Text for confirm delete")
    static let cancel = LocalizedStringResource("common.cancel", defaultValue: "Cancel", table: "Localizable", comment: "Text for cancel")

    static let sort = LocalizedStringResource("common.sort", defaultValue: "Sort", table: "Localizable", comment: "common sort")
    static let sortByTimestamp = LocalizedStringResource("common.sortByTimestamp", defaultValue: "By timestamp", table: "Localizable", comment: "label for sort by date")
    static let sortByName = LocalizedStringResource("common.sortByName", defaultValue: "By name", table: "Localizable", comment: "label for sort by name")
    static let sortByMomentCount = LocalizedStringResource("common.sortByMomentCount", defaultValue: "By moment count", table: "Localizable", comment: "label for sort by number of moments")
  }

  enum Permission {
    public static let localAuthReason = LocalizedStringResource("Permission.localAuthReason", defaultValue: "Used to restrict unauthorized users from accessing your data.", table: "Localizable", comment: "localAuthReason for face id. Show to user when requesting face id")
  }
}

extension DiaryStringKey {
  enum Data {
    public static let privacyPolicyLabel = LocalizedStringResource("privacy.policy.label", defaultValue: "Privacy Policy", table: "Localizable", bundle: .module, comment: "label for privacy policy")
    public static let termOfUseLabel = LocalizedStringResource("privacy.termOfUse.label", defaultValue: "Terms of Use", table: "Localizable", bundle: .module, comment: "label for Terms of Use")

    enum Export {
      public static let shareLinkLabel = LocalizedStringResource("export.total.sharelinkLabel", defaultValue: "Export data", table: "Localizable", bundle: .module, comment: "label used when exporting all data")

      public static let subject = LocalizedStringResource("export.total.subject", defaultValue: "HDiary data", table: "Localizable", bundle: .module, comment: "subject when exporting all raw data")

      public static func message(_ appName: String) -> LocalizedStringResource {
        LocalizedStringResource("export.total.message", defaultValue: "This is the exported data from \(appName)", table: "Localizable", bundle: .module, comment: "message when exporting all raw data, parameter is the app name")
      }
    }

    enum StorageUsage {
      public static let storageUsage = LocalizedStringResource("date.StorageUsage.storageUsage", defaultValue: "Storage Usage", table: "Localizable", bundle: .module, comment: "label for storage usage")

      public static let cachedStorageLabel = LocalizedStringResource("date.StorageUsage.cached.label", defaultValue: "Local Cache", table: "Localizable", bundle: .module, comment: "label text for local cache data")
      public static let calculatingLocalCacheLabel = LocalizedStringResource("date.StorageUsage.cached.calculatingLabel", defaultValue: "Calculating...", table: "Localizable", bundle: .module, comment: "label text shown to user when calculating local cache")
      public static let cachedStorageDescription = LocalizedStringResource("date.StorageUsage.cached.description", defaultValue: "Cached data consists of temporary content like images and documents and can be safely removed.", table: "Localizable", bundle: .module, comment: "description text for local cache data")

      public static let cloudStorageLabel = LocalizedStringResource("date.StorageUsage.cloud.label", defaultValue: "Cloud Media", table: "Localizable", bundle: .module, comment: "label for cloud media")
      public static let cloudStorageDescription = LocalizedStringResource("date.StorageUsage.cloud.description", defaultValue: "Media stored in iCloud, synchronized across all your devices.", table: "Localizable", bundle: .module, comment: "description text for cloud media")
      public static let cloudStorageViewByMedia = LocalizedStringResource("date.StorageUsage.cloud.viewByMedia", defaultValue: "View By Media", table: "Localizable", bundle: .module, comment: "label for ViewByMedia")
      public static let cloudStorageViewByMoment = LocalizedStringResource("date.StorageUsage.cloud.viewByMoment", defaultValue: "View By Moment", table: "Localizable", bundle: .module, comment: "label for ViewByMoment")
      static let sortByMomentStorage = LocalizedStringResource("date.StorageUsage.sortByMomentStorage", defaultValue: "By media storage", table: "Localizable", comment: "label for sort by moment's media storage")

      public static func mediaItemStorageSummary(for itemCount: Int, sizeInBytes: String) -> LocalizedStringResource {
        LocalizedStringResource(
          "date.StorageUsage.cloud itemCount ",
          defaultValue: "\(itemCount) items, \(sizeInBytes) in total.",
          table: "Localizable",
          bundle: .module,
          comment: "summary of total size for given media items"
        )
      }
    }

    enum CloudData {
      public static let cellLabel = LocalizedStringResource("CloudData.cellLabel", defaultValue: "Cloud Data", table: "Localizable", bundle: .module, comment: "label used to show cloud data in SettingView")

      public static let syncing = LocalizedStringResource("CloudData.syncing", defaultValue: "syncing...", table: "Localizable", bundle: .module, comment: "label used to show cloud data is syncing")

      public static let allContent = LocalizedStringResource("CloudData.allContent", defaultValue: "All content", table: "Localizable", bundle: .module, comment: "label used to show cloud data is all displayed")

      public static let loadMore = LocalizedStringResource("CloudData.loadMore", defaultValue: "Load more", table: "Localizable", bundle: .module, comment: "label used to show cloud data can load more")

      public static let loadMoreFail = LocalizedStringResource("CloudData.loadMoreFail", defaultValue: "fetch more failed, tap to retry", table: "Localizable", bundle: .module, comment: "label used to show cloud data load more fail, user can tap to resty")

      public static let loadFail = LocalizedStringResource("CloudData.loadFail", defaultValue: "Load failed", table: "Localizable", bundle: .module, comment: "label used to show cloud data load failed")

      public static let lastUpdateTime = LocalizedStringResource("CloudData.lastUpdateTime", defaultValue: "Last update date", table: "Localizable", bundle: .module, comment: "label used to show cloud data last update time")
      public static let noData = LocalizedStringResource("CloudData.noData", defaultValue: "No data", table: "Localizable", bundle: .module, comment: "label used to show no cloud data")
    }
  }
}

extension DiaryStringKey {
  enum IAP {
    public static let subscribe = LocalizedStringResource("iap.subscribe", defaultValue: "Subscribe", table: "Localizable", bundle: .module, comment: "Subscribe")

    enum RecordSubscriptionPromotion {
      public static let checkDetail = LocalizedStringResource("iap.RecordSubscriptionPromotion.checkDetail", defaultValue: "Check Detail", table: "Localizable", bundle: .module, comment: "Check Detail button title in RecordSubscriptionPromotion view")
      public static let skip = LocalizedStringResource("iap.RecordSubscriptionPromotion.skip", defaultValue: "Skip", table: "Localizable", bundle: .module, comment: "Skip button title in RecordSubscriptionPromotion view")

      public static let title = LocalizedStringResource("iap.RecordSubscriptionPromotion.title", defaultValue: "Unlock unlimited Happy Moments?", table: "Localizable", bundle: .module, comment: "title shown in RecordSubscriptionPromotion view")

      public static func description(_ maxFreeCount: Int) -> LocalizedStringResource {
        LocalizedStringResource(
          "iap.RecordSubscriptionPromotion.description with max free count %@",
          defaultValue: "You have \(maxFreeCount) happy moments for free, subscribe to unlock unlimited happy moments!",
          table: "Localizable",
          bundle: .module,
          comment: "description shown in RecordSubscriptionPromotion view"
        )
      }
    }
  }
}

extension DiaryStringKey {
  enum AppInfo {
    public static let about = LocalizedStringResource("AppInfo.about", defaultValue: "About", table: "Localizable", bundle: .module, comment: "About label in Settings")
    public static let icpNumberLabel = LocalizedStringResource("AppInfo.icpNumberLabel", defaultValue: "China Mainland ICP Filing Number ", table: "Localizable", bundle: .module, comment: "icp Number Label in About")

    public static func icpNumberContent(_ content: String) -> LocalizedStringResource {
      LocalizedStringResource(
        "AppInfo.icpNumberContent %@",
        defaultValue: "China Mainland ICP Filing Number \(content)",
        table: "Localizable",
        bundle: .module,
        comment: "icp Number Content"
      )
    }
  }
}

// MARK: - Search

extension DiaryStringKey {
  enum Search {
    public static let emptyResult = LocalizedStringResource("search.emptyResult", defaultValue: "No results found", table: "Localizable", bundle: .module, comment: "empty result string for search")

    public static let searchError = LocalizedStringResource(
      "search.error.title",
      defaultValue: "Search Error",
      table: "Localizable",
      bundle: .module,
      comment: "Title shown when search operation fails"
    )

    public static let searching = LocalizedStringResource(
      "search.searching",
      defaultValue: "Searching...",
      table: "Localizable",
      bundle: .module,
      comment: "Text shown when search is in progress"
    )

    public static let recommended = LocalizedStringResource(
      "search.recommend.title",
      defaultValue: "Recommended",
      table: "Localizable",
      bundle: .module,
      comment: "Title shown in search recommendation section"
    )

//    public static func icpNumberContent(_ content: String) -> LocalizedStringResource {
//      LocalizedStringResource(
//        "AppInfo.icpNumberContent %@",
//        defaultValue: "China Mainland ICP Filing Number \(content)",
//        table: "Localizable",
//        bundle: .module,
//        comment: "icp Number Content"
//      )
//    }
  }
}

#endif
