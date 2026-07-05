# Task 6 Report

## 1. STATUS

DONE_WITH_CONCERNS

## 2. Commits created

- `2df7c1f fix: restore root test plan` — verification-only fix restoring unintended `HDiary.xctestplan` branch diff so allowed non-renames match the brief.
- `5278775 docs: add swift package migration plan` — committed `docs/superpowers/plans/2026-07-05-swift-package-product-migration.md` with the exact requested docs commit message/trailer.

## 3. Source-location verification outputs

### Project-owned Swift files

```text
--- HDiary ---
HDiary/HDiaryApp.swift
--- HDiaryWidget ---
HDiaryWidget/HDiaryWidgetBundle.swift
--- HDiaryTests ---
--- HDiaryUITests ---
```

Result: matches expected app/widget shims only; no project-owned unit/UI Swift files remain under the old test target directories.

### Package Swift counts

```text
HDiaryLibrary/Sources/HDiaryAppFeature: 117
HDiaryLibrary/Sources/HDiaryWidgetFeature: 6
HDiaryLibrary/Tests/HDiaryAppFeatureTests: 2
HDiaryLibrary/UITests/HDiaryUITests: 2
```

Result: migrated package tree contains the moved app/widget/unit/UI Swift files; old Xcode target directories retain only the two shims.

## 4. Build/test commands/tools run and outcomes

### XcodeBuildMCP defaults

- `xcodebuildmcp-session_show_defaults`: active defaults already pointed to this worktree, scheme `HDiary`, simulator `hdiary 17pro` (`A044BA15-7770-48E6-8E28-E2123A772ACD`).
- `xcodebuildmcp-session_set_defaults` for `HDiary` used the exact projectPath/scheme/simulator values from the brief.
- Cleared stale MCP `configuration` default after the exact brief `extraArgs` with `-configuration Debug` failed as duplicated by the tool (`option -configuration may only be provided once`).

### App build

- MCP exact build attempt with `extraArgs ["-configuration","Debug","CODE_SIGN_IDENTITY=-"]`: failed immediately because xcodebuildmcp supplied duplicate `-configuration`.
- MCP build retry with `extraArgs ["CODE_SIGN_IDENTITY=-"]`: failed during SwiftPM resolution with `fatal: cannot use bare repository ... safe.bareRepository is explicit`.
- Raw fallback: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all` plus full 1082 proxy env, `xcodebuild -project HDiary.xcodeproj -scheme HDiary -destination id=A044BA15-7770-48E6-8E28-E2123A772ACD -configuration Debug CODE_SIGN_IDENTITY=- build`.
- Outcome: PASS, `** BUILD SUCCEEDED **`.

### App tests

- MCP `xcodebuildmcp-test_sim` with `extraArgs ["CODE_SIGN_IDENTITY=-"]`, `progress: true`: discovered 18 tests, then failed during SwiftPM resolution with `safe.bareRepository is explicit` and clone/network failure.
- Raw fallback: same one-shot safe.bareRepository override plus full 1082 proxy env, `xcodebuild -project HDiary.xcodeproj -scheme HDiary -destination id=A044BA15-7770-48E6-8E28-E2123A772ACD -configuration Debug CODE_SIGN_IDENTITY=- test`.
- Outcome: PASS, `** TEST SUCCEEDED **`.

### Widget build

- `xcodebuildmcp-session_set_defaults` for `HDiaryWidgetExtension` used the exact projectPath/scheme/simulator values from the brief.
- MCP build with `extraArgs ["CODE_SIGN_IDENTITY=-"]`: failed during SwiftPM resolution with `safe.bareRepository is explicit` plus clone/network failure.
- Raw fallback: same one-shot safe.bareRepository override plus full 1082 proxy env, `xcodebuild -project HDiary.xcodeproj -scheme HDiaryWidgetExtension -destination id=A044BA15-7770-48E6-8E28-E2123A772ACD -configuration Debug CODE_SIGN_IDENTITY=- build`.
- Outcome: PASS, `** BUILD SUCCEEDED **`.

## 5. Resource non-migration audit result

Command output for the forbidden resource path audit:

```text
```

Result: no output; forbidden resources were not migrated.

## 6. Rename-heavy diff audit result

### Non-rename entries in `git diff --name-status -M main...HEAD | sed -n 1,220p`

```text
M	HDiary.xcodeproj/project.pbxproj
M	HDiary/HDiary.xctestplan
M	HDiary/HDiaryApp.swift
M	HDiaryLibrary/Package.swift
A	HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift
A	HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetBundle.swift
M	HDiaryWidget/HDiaryWidgetBundle.swift
A	docs/superpowers/plans/2026-07-05-swift-package-product-migration.md
A	docs/superpowers/specs/2026-07-05-swift-package-migration-design.md
```

Result: non-rename modifications are limited to the allowed files from the brief. The unintended root `HDiary.xctestplan` modification was restored in commit `2df7c1f`; active scheme references `HDiary/HDiary.xctestplan`. App/widget/unit/UI Swift moves are represented primarily as `R` renames, with expected lower similarity scores only where package migration adjusted imports/access.

### Full first 220 name-status lines

```text
M	HDiary.xcodeproj/project.pbxproj
M	HDiary/HDiary.xctestplan
M	HDiary/HDiaryApp.swift
M	HDiaryLibrary/Package.swift
R100	HDiary/BaseTabView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/BaseTabView.swift
R100	HDiary/Common/Bootstrap/AppDelegate.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Bootstrap/AppDelegate.swift
R100	HDiary/Common/Design.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Design.swift
R100	HDiary/Common/DiaryStringKey.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/DiaryStringKey.swift
R100	HDiary/Common/LocalAuth.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/LocalAuth.swift
R100	HDiary/Common/Navigation/ActivityHandler.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/ActivityHandler.swift
R100	HDiary/Common/Navigation/AppEnvironments.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/AppEnvironments.swift
R100	HDiary/Common/Navigation/HDiaryNavigatorModifier.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/HDiaryNavigatorModifier.swift
R100	HDiary/Common/Navigation/HDiaryRoute.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/HDiaryRoute.swift
R100	HDiary/Common/Navigation/NavigationStore.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/NavigationStore.swift
R100	HDiary/Common/Navigation/PresentationRegistry.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/PresentationRegistry.swift
R100	HDiary/Common/Navigation/UrlHandler.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Navigation/UrlHandler.swift
R100	HDiary/Common/Notification/LocalNotificationManager.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Notification/LocalNotificationManager.swift
R100	HDiary/Common/Util/MediaItem+Util.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Common/Util/MediaItem+Util.swift
A	HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift
R100	HDiary/IAP/RecordSubscriptionPromotionView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/IAP/RecordSubscriptionPromotionView.swift
R100	HDiary/Library/Chart/Entry/ChartEntry.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/Entry/ChartEntry.swift
R100	HDiary/Library/Chart/Entry/ChartEntryView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/Entry/ChartEntryView.swift
R100	HDiary/Library/Chart/Entry/ChartEntryWrapperView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/Entry/ChartEntryWrapperView.swift
R100	HDiary/Library/Chart/RatingPieChart/MomentRatingPieChartView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/RatingPieChart/MomentRatingPieChartView.swift
R100	HDiary/Library/Chart/RatingPieChart/TimeConstrainedMomentListView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/RatingPieChart/TimeConstrainedMomentListView.swift
R100	HDiary/Library/Chart/RatingPieChart/TimeRangePickerView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/RatingPieChart/TimeRangePickerView.swift
R100	HDiary/Library/Chart/RatingPieChart/TimeRangeSegmentControl.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/RatingPieChart/TimeRangeSegmentControl.swift
R100	HDiary/Library/Chart/TagChart/TagChartView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Chart/TagChart/TagChartView.swift
R100	HDiary/Library/Entry/LibraryEntry.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntry.swift
R100	HDiary/Library/Entry/LibraryEntryCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryCell.swift
R100	HDiary/Library/Entry/LibraryEntryDetailWrapperView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Entry/LibraryEntryDetailWrapperView.swift
R100	HDiary/Library/LibraryView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/LibraryView.swift
R100	HDiary/Library/Participant/AllParticipantsView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Participant/AllParticipantsView.swift
R100	HDiary/Library/Participant/AvatarImageView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Participant/AvatarImageView.swift
R100	HDiary/Library/Participant/ParticipantDetail/ParticipantDetailView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Participant/ParticipantDetail/ParticipantDetailView.swift
R100	HDiary/Library/Participant/ParticipantEdit/AvatarSelectionView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Participant/ParticipantEdit/AvatarSelectionView.swift
R100	HDiary/Library/Participant/ParticipantEdit/ParticipantAddEditView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Participant/ParticipantEdit/ParticipantAddEditView.swift
R100	HDiary/Library/Participant/ParticipantListItemView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Participant/ParticipantListItemView.swift
R100	HDiary/Library/Tags/TagDetail/TagDetailView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagDetail/TagDetailView.swift
R100	HDiary/Library/Tags/TagEdit/TagEditView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagEdit/TagEditView.swift
R100	HDiary/Library/Tags/TagList/AllTagsView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagList/AllTagsView.swift
R100	HDiary/Library/Tags/TagList/AllTagsViewState.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagList/AllTagsViewState.swift
R100	HDiary/Library/Tags/TagList/NoTagView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagList/NoTagView.swift
R100	HDiary/Library/Tags/TagList/TagCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagList/TagCell.swift
R100	HDiary/Library/Tags/TagList/TagSortMenu.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagList/TagSortMenu.swift
R100	HDiary/Moments/AddMoment/AddMomentNavigationView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/AddMoment/AddMomentNavigationView.swift
R100	HDiary/Moments/MomentCloudState/MomentCloudStateManager.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentCloudState/MomentCloudStateManager.swift
R100	HDiary/Moments/MomentDetail/MomentDetailView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentDetail/MomentDetailView.swift
R096	HDiary/Moments/MomentDetail/TagListView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentDetail/TagListView.swift
R100	HDiary/Moments/MomentEditView/Media/HappyImageThumbnailNail.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentEditView/Media/HappyImageThumbnailNail.swift
R100	HDiary/Moments/MomentEditView/Media/MediaThumbnailView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentEditView/Media/MediaThumbnailView.swift
R100	HDiary/Moments/MomentEditView/Media/MomentMediaEditView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentEditView/Media/MomentMediaEditView.swift
R100	HDiary/Moments/MomentEditView/MomentEditView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentEditView/MomentEditView.swift
R100	HDiary/Moments/MomentEditView/MomentParticipantEditView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentEditView/MomentParticipantEditView.swift
R100	HDiary/Moments/MomentEditView/MomentTagEditSection.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentEditView/MomentTagEditSection.swift
R100	HDiary/Moments/MomentList/AddMomentMenu.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/AddMomentMenu.swift
R100	HDiary/Moments/MomentList/AllList/AllMomentListScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/AllList/AllMomentListScreen.swift
R100	HDiary/Moments/MomentList/Filter/MomentFilter.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/Filter/MomentFilter.swift
R100	HDiary/Moments/MomentList/Filter/MomentFilterMenu.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/Filter/MomentFilterMenu.swift
R100	HDiary/Moments/MomentList/MomentGroupIdView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/MomentGroupIdView.swift
R096	HDiary/Moments/MomentList/MomentItemView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/MomentItemView.swift
R100	HDiary/Moments/MomentList/MomentListItemView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/MomentListItemView.swift
R100	HDiary/Moments/MomentList/MomentTab.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/MomentTab.swift
R100	HDiary/Moments/MomentList/RecentList/MomentListScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/RecentList/MomentListScreen.swift
R100	HDiary/Moments/MomentList/RecentList/RecentMomentListModel.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/RecentList/RecentMomentListModel.swift
R100	HDiary/Moments/MomentList/RecentList/RecentSection.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/RecentList/RecentSection.swift
R100	HDiary/Moments/MomentList/Section/Section.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/Section/Section.swift
R100	HDiary/Moments/SuggestedMoment/MomentSuggestionUtil.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/SuggestedMoment/MomentSuggestionUtil.swift
R100	HDiary/Moments/SuggestedMoment/SuggestionUnavailableView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Moments/SuggestedMoment/SuggestionUnavailableView.swift
R100	HDiary/Search/View/SearchEmptyView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchEmptyView.swift
R100	HDiary/Search/View/SearchErrorView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchErrorView.swift
R100	HDiary/Search/View/SearchModifier.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchModifier.swift
R100	HDiary/Search/View/SearchProgressView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchProgressView.swift
R100	HDiary/Search/View/SearchRecommendView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchRecommendView.swift
R100	HDiary/Search/View/SearchResultView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchResultView.swift
R100	HDiary/Search/View/SearchView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Search/View/SearchView.swift
R100	HDiary/Settings/Data/CloudData/CloudDataCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/CloudDataCell.swift
R100	HDiary/Settings/Data/CloudData/CloudDataDetail/CloudDataDetailScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/CloudDataDetail/CloudDataDetailScreen.swift
R100	HDiary/Settings/Data/CloudData/CloudDataDetail/CloudDataModel.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/CloudDataDetail/CloudDataModel.swift
R100	HDiary/Settings/Data/CloudData/CloudRecord.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/CloudRecord.swift
R100	HDiary/Settings/Data/CloudData/Entry/CloudDataEntryModel.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Entry/CloudDataEntryModel.swift
R100	HDiary/Settings/Data/CloudData/Entry/CloudDataEntryScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Entry/CloudDataEntryScreen.swift
R100	HDiary/Settings/Data/CloudData/Entry/DataEntryCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/CloudData/Entry/DataEntryCell.swift
R100	HDiary/Settings/Data/DateUsageCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/DateUsageCell.swift
R100	HDiary/Settings/Data/ExportDataCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/ExportDataCell.swift
R100	HDiary/Settings/Data/StorageUsage/CloudStorage/ByMedia/MediaItemDeleteView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/CloudStorage/ByMedia/MediaItemDeleteView.swift
R100	HDiary/Settings/Data/StorageUsage/CloudStorage/ByMedia/MediaStorageView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/CloudStorage/ByMedia/MediaStorageView.swift
R100	HDiary/Settings/Data/StorageUsage/CloudStorage/ByMoment/MomentStorageDetailScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/CloudStorage/ByMoment/MomentStorageDetailScreen.swift
R100	HDiary/Settings/Data/StorageUsage/CloudStorage/ByMoment/MomentStorageView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/CloudStorage/ByMoment/MomentStorageView.swift
R100	HDiary/Settings/Data/StorageUsage/CloudStorage/CloudStorageSection.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/CloudStorage/CloudStorageSection.swift
R100	HDiary/Settings/Data/StorageUsage/CloudStorage/MediaStorageInfoView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/CloudStorage/MediaStorageInfoView.swift
R100	HDiary/Settings/Data/StorageUsage/LocalCacheView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/LocalCacheView.swift
R100	HDiary/Settings/Data/StorageUsage/StorageUsageView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Data/StorageUsage/StorageUsageView.swift
R100	HDiary/Settings/Debug/CollectLog/CollectLogView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/CollectLog/CollectLogView.swift
R100	HDiary/Settings/Debug/DebugDetailView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/DebugDetailView.swift
R100	HDiary/Settings/Debug/DebugEntryCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/DebugEntryCell.swift
R100	HDiary/Settings/Debug/IAP/IAPDebugScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/IAP/IAPDebugScreen.swift
R100	HDiary/Settings/Debug/RawData/RawData.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/RawData/RawData.swift
R100	HDiary/Settings/Debug/RawData/RawDataDetailView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/RawData/RawDataDetailView.swift
R100	HDiary/Settings/Debug/RawData/RawDataItemView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/RawData/RawDataItemView.swift
R100	HDiary/Settings/Debug/RawData/RawDataView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/RawData/RawDataView.swift
R100	HDiary/Settings/Debug/Search/SearchDebugScreen.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/Search/SearchDebugScreen.swift
R100	HDiary/Settings/Debug/SwiftDataDebug/SwiftDataDebugInsertMomentButton.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/SwiftDataDebug/SwiftDataDebugInsertMomentButton.swift
R100	HDiary/Settings/Debug/SwiftDataDebug/SwiftDataDebugMessageStatusView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/SwiftDataDebug/SwiftDataDebugMessageStatusView.swift
R100	HDiary/Settings/Debug/SwiftDataDebug/SwiftDataDebugView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Debug/SwiftDataDebug/SwiftDataDebugView.swift
R100	HDiary/Settings/HelpAndFeedback/About/AboutCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/About/AboutCell.swift
R100	HDiary/Settings/HelpAndFeedback/About/HDiaryAboutView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/About/HDiaryAboutView.swift
R100	HDiary/Settings/HelpAndFeedback/About/ICPNumberCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/About/ICPNumberCell.swift
R100	HDiary/Settings/HelpAndFeedback/HelpAndFeedbackCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/HelpAndFeedbackCell.swift
R100	HDiary/Settings/HelpAndFeedback/HelpAndFeedbackView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/HelpAndFeedbackView.swift
R095	HDiary/Settings/HelpAndFeedback/PrivacyCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/PrivacyCell.swift
R095	HDiary/Settings/HelpAndFeedback/TermOfUseCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/HelpAndFeedback/TermOfUseCell.swift
R100	HDiary/Settings/LocalNotification/LocalNotificationPermissionReminderView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/LocalNotification/LocalNotificationPermissionReminderView.swift
R100	HDiary/Settings/LocalNotification/LocalNotificationSettingView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/LocalNotification/LocalNotificationSettingView.swift
R100	HDiary/Settings/LocalNotification/LocalNotifictionConfigCell.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/LocalNotification/LocalNotifictionConfigCell.swift
R100	HDiary/Settings/Model/SettingsEntry.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/Model/SettingsEntry.swift
R100	HDiary/Settings/SettingsView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/Settings/SettingsView.swift
R100	HDiary/SharedCode/SwiftUI/HImagePicker/HImagePicker.swift	HDiaryLibrary/Sources/HDiaryAppFeature/SharedCode/SwiftUI/HImagePicker/HImagePicker.swift
R100	HDiary/SharedCode/SwiftUI/HImagePicker/HImagePickerDefaultLabel.swift	HDiaryLibrary/Sources/HDiaryAppFeature/SharedCode/SwiftUI/HImagePicker/HImagePickerDefaultLabel.swift
R100	HDiary/SharedCode/SwiftUI/HImagePicker/HPhoto.swift	HDiaryLibrary/Sources/HDiaryAppFeature/SharedCode/SwiftUI/HImagePicker/HPhoto.swift
R089	HDiary/SharedCode/SwiftUI/Preview/HDataPreviewView.swift	HDiaryLibrary/Sources/HDiaryAppFeature/SharedCode/SwiftUI/Preview/HDataPreviewView.swift
A	HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetBundle.swift
R100	HDiaryWidget/HDiaryWidgetLiveActivity.swift	HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetLiveActivity.swift
R100	HDiaryWidget/MomentWidget/MomentTimeLineProvider.swift	HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentTimeLineProvider.swift
R097	HDiaryWidget/MomentWidget/MomentWidget.swift	HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentWidget.swift
R100	HDiaryWidget/MomentWidget/MomentWidgetIntent.swift	HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentWidgetIntent.swift
R100	HDiaryWidget/MomentWidget/MomentWidgetUtil.swift	HDiaryLibrary/Sources/HDiaryWidgetFeature/MomentWidget/MomentWidgetUtil.swift
R091	HDiaryTests/AllTagsViewTests.swift	HDiaryLibrary/Tests/HDiaryAppFeatureTests/AllTagsViewTests.swift
R100	HDiaryTests/HDiaryTests.swift	HDiaryLibrary/Tests/HDiaryAppFeatureTests/HDiaryTests.swift
R100	HDiaryUITests/HDiaryUITests.swift	HDiaryLibrary/UITests/HDiaryUITests/HDiaryUITests.swift
R100	HDiaryUITests/HDiaryUITestsLaunchTests.swift	HDiaryLibrary/UITests/HDiaryUITests/HDiaryUITestsLaunchTests.swift
M	HDiaryWidget/HDiaryWidgetBundle.swift
A	docs/superpowers/plans/2026-07-05-swift-package-product-migration.md
A	docs/superpowers/specs/2026-07-05-swift-package-migration-design.md
```

## 7. Current git status after task

```text
## huahuahu-migrate-swift-files-to-package
```

## 8. Concerns

- xcodebuildmcp still cannot complete SwiftPM resolution in this environment because SwiftPM package caches hit `safe.bareRepository is explicit`; raw `xcodebuild` fallback with the one-shot Git override and full 1082 proxy succeeded for app build, app tests, and widget build.
- xcodebuildmcp rejected the brief’s literal `-configuration Debug` `extraArgs` as a duplicate option due an existing/tool-supplied configuration; equivalent raw fallback used `-configuration Debug` explicitly and passed.

## 9. Review finding fix: root test plan stale target

### Files changed

- `HDiary.xctestplan`
- `.superpowers/sdd/task-6-report.md`

### Validation

```text
rg 'HDiaryTests|60A4E20F2A3DDCE3000E68A0' HDiary.xctestplan HDiary/HDiary.xctestplan HDiary.xcodeproj/project.pbxproj
No matches found.

plutil -lint HDiary.xctestplan HDiary/HDiary.xctestplan
HDiary.xctestplan: (Unexpected character { at line 1)
HDiary/HDiary.xctestplan: (Unexpected character { at line 1)

plutil -p HDiary.xctestplan >/dev/null && plutil -p HDiary/HDiary.xctestplan >/dev/null
passed

xcodebuildmcp-test_sim extraArgs ["CODE_SIGN_IDENTITY=-"]
failed during SwiftPM resolution with safe.bareRepository/cache and network errors.

GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all xcodebuild test -project HDiary.xcodeproj -scheme HDiary -destination 'id=A044BA15-7770-48E6-8E28-E2123A772ACD' -configuration Debug CODE_SIGN_IDENTITY=-
passed
```

### Commit

- `fix: keep root test plan on package tests`

### Concerns

- `/usr/bin/plutil -lint` in this environment rejects JSON `.xctestplan` files with `Unexpected character { at line 1`; `plutil -p`, `plutil -convert json`, and `python3 -m json.tool`-equivalent parsing all validate the same files.
