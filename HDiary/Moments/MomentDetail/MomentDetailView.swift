//
//  MomentDetailView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import HDiaryModel
import HUIComponent
import PhotosUI
import SwiftData
import SwiftUI

struct MomentDetailView: View {
  let moment: Moment
  let canEdit: Bool

  @State private var isEditing = false

  var body: some View {
    MomentDetailInnerView(moment: moment)
      .onAppear {
        moment.lastVisitDate = Date()
        moment.increaseVisitCount()
      }
      .toolbar(content: {
        ToolbarItem(placement: .primaryAction) {
          if canEdit {
            Button {
              isEditing = true
            } label: {
              Label(
                title: { Text(DiaryStringKey.edit) },
                icon: { Image(hDiarySymbol: .edit) }
              )
              .labelStyle(.iconOnly)
            }
          }
        }
      })
      .sheet(isPresented: $isEditing, content: {
        editView
      })
  }

  @MainActor
  private var editView: some View {
    NavigationStack {
      EditMomentView(initialMoment: moment) { _ in
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct MomentDetailInnerView: View {
  @ScaledMetric private var verticalPadding = 10
  let moment: Moment
  @Environment(MomentCloudStateManager.self) private var momentCloudStateManager
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ScrollView {
      VStack(
        alignment: .leading,
        spacing: verticalPadding,
        content: {
          titleView
          timestampView
          if !moment.sortedParticipants.isEmpty {
            participantView
          }

          if !moment.sortedTags.isEmpty {
            TagListView(tags: moment.sortedTags)
          }
          ratingView
          HStack {
            Text(moment.content)
              .padding()
          }
          if !moment.sortedMediaItemAndThumbnails.isEmpty {
            imageListView
          }
        }
      )
    }
    .navigationTitle(Text(DiaryStringKey.momentDetailViewNavigationTitle))
  }

  @MainActor @ViewBuilder
  var imageListView: some View {
    HMediaItemPageView(itemAndThumbails: moment.sortedMediaItemAndThumbnails)
      .frame(minHeight: 300)
  }

  @ViewBuilder
  private var timestampView: some View {
    ScrollView(.horizontal) {
      HStack {
        Image(systemName: "clock")
        Text(moment.timestamp, style: .date)
        Text(moment.timestamp, style: .time)
      }
    }
    .padding(.horizontal)
    .foregroundStyle(.gray)
  }

  @ViewBuilder
  private var titleView: some View {
    MomentTitleView(title: moment.title, cloudStatus: momentCloudStateManager.momentCloudStatus[moment.uuid])
  }

  @ViewBuilder
  private var ratingView: some View {
    if let rating = HRating(rawValue: moment.rating) {
      HRatingView(
        model: HRatingModel(onColor: .accentColor),
        rating: .constant(rating)
      )
      .allowsHitTesting(false)
      .scaleEffect(0.65, anchor: .leading)
      .padding(.horizontal)
    }
  }

  @ViewBuilder
  private var participantView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        Image(systemName: "person")
        ForEach(moment.sortedParticipants) { participant in
          NavigationLink(value: HDiaryDestination.participant(participant)) {
            Text(participant.nickName)
          }
        }
      }
      .padding(.horizontal)
      .foregroundStyle(.gray)
    }
  }
}

private extension Moment {
  var sortedParticipants: [Participant] {
    return participants?.sorted {
      $0.nickName.localizedStandardCompare($1.nickName) == .orderedAscending
    } ?? []
  }

  var sortedTags: [Tag] {
    getLocalizedComparedTags() ?? []
  }

  var sortedMediaItemAndThumbnails: [MediaItemAndThumbnail] {
    let newSchemaImages = mediaItems?
      .filter {
        $0.mediaType == .image || $0.mediaType == .gif
      }
      .sorted { $0.createDate < $1.createDate }
      .compactMap {
        MediaItemAndThumbnail(mediaItem: $0)
      }
      ?? []
    let legacySchemaImages = images?
      .sorted { $0.creationDate < $1.creationDate }
      .compactMap { MediaItemAndThumbnail(happyImage: $0) }
      ?? []
    return legacySchemaImages + newSchemaImages
  }
}

@MainActor
private struct MomentTitleView: View {
  let title: String
  let cloudStatus: MomentCloudStatus?

  @State private var cloudIconTapped = false

  var body: some View {
    if let cloudStatus, cloudStatus == .notSynced {
      HStack {
        cloudButton
        titleView
        Spacer()
      }
      .padding()
    }
    else {
      HStack {
        titleView
          .padding()
        Spacer()
      }
    }
  }

  private var titleView: some View {
    Text(title)
      .font(.title)
      .multilineTextAlignment(.leading)
  }

  private var cloudButton: some View {
    Button {
      cloudIconTapped = true
    } label: {
      Label {
        Text(DiaryStringKey.Moment.CloudSync.syncingLabel)
      } icon: {
        Image(hDiarySymbol: .iCloud)
          .symbolVariant(.slash)
      }
      .labelStyle(.iconOnly)
    }
    .sheet(isPresented: $cloudIconTapped) {
      SyncStatusView()
        .presentationDetents([.medium])
    }
  }
}

// View to show current item is syncing to iCloud
@MainActor private struct SyncStatusView: View {
  @ScaledMetric private var padding: Double = 20.0
  var body: some View {
    ScrollView {
      VStack(spacing: padding) {
        // Title
        Text(DiaryStringKey.Moment.CloudSync.syncingSheetTitle)
          .font(.title)
          .fontWeight(.bold)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)

        // Subtitle
        Text(DiaryStringKey.Moment.CloudSync.syncingSheetText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)

        // Progress Indicator
        ProgressView()
          .progressViewStyle(.circular)
          .padding()
        Spacer()
      }
      .padding()
    }
    .scrollIndicators(.never)
  }
}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview(traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var moments: [Moment]
    return NavigationStack {
      MomentDetailView(moment: moments.first!, canEdit: true)
        .navigationBarTitleDisplayMode(.inline)
    }
    .previewEnvironment()
  }

  #Preview("sync status") { @MainActor in
    NavigationStack(root: {
      ScrollView {
        VStack(alignment: .leading) {
          MomentTitleView(title: "Test Title", cloudStatus: .notSynced)
            .border(.red, width: 1)
          MomentTitleView(title: "Test Title", cloudStatus: .synced)
            .border(.red, width: 1)
        }
      }

    })
  }

  #Preview("present Sync status") { @MainActor in
    NavigationStack(root: {
      Text(verbatim: "test")
        .sheet(isPresented: .constant(true)) {
          SyncStatusView()
            .presentationDetents([.medium])
        }

    })
  }
#endif
