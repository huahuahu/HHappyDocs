//
//  MomentListItemView.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/25.
//

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

/// Used in MomentList as cell
struct MomentListItemView: View {
  @ScaledMetric private var paddingBelowTitle = 10.0
  @ScaledMetric private var thumbnailSize = 40.0
  @ScaledMetric private var thumbnailLeadingPadding = 10.0
  @Environment(\.modelContext) private var modelContext
  @Environment(MomentCloudStateManager.self) private var momentCloudStateManager

  @State private var isEditing = false

  let moment: Moment
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: paddingBelowTitle) {
        titleView
        tagView
      }
      Spacer(minLength: thumbnailLeadingPadding)
      thumbnailView
    }
    .sheet(isPresented: $isEditing, content: {
      NavigationStack {
        EditMomentView(initialMoment: moment) { _ in
        }
        .navigationBarTitleDisplayMode(.inline)
      }
    })
    .swipeActions(edge: .leading, allowsFullSwipe: false) {
      swipeEditButton()
    }
  }

  @ViewBuilder private var titleView: some View {
    if let cloudStatus = momentCloudStateManager.momentCloudStatus[moment.uuid],
       cloudStatus == .notSynced {
      HStack {
        Image(hDiarySymbol: .iCloud)
          .symbolVariant(.slash)
        Text(moment.title)
          .lineLimit(1)
          .font(.headline.bold())
          .foregroundStyle(.primary)
      }
    }
    else {
      Text(moment.title)
        .lineLimit(1)
        .font(.headline.bold())
        .foregroundStyle(.primary)
    }
  }

  @ViewBuilder
  private var tagView: some View {
    if let tags = moment.getLocalizedComparedTags(), !tags.isEmpty {
      HStack {
        Image(hDiarySymbol: .tag)
        ForEach(tags.indices, id: \.self) { innerIndex in
          Text(tags[innerIndex].title)
            .lineLimit(1)
            .layoutPriority(Double(tags.count - innerIndex))
        }
        Spacer()
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var thumbnailView: some View {
    if let thumbnail = moment.getThumbnail() {
      Image(uiImage: thumbnail)
        .resizable()
        .aspectRatio(1.0, contentMode: .fill)
        .frame(width: thumbnailSize, height: thumbnailSize)
    }
  }

  private func swipeEditButton() -> some View {
    Button {
      isEditing = true
      moment.increaseVisitCount()
    } label: {
      Label(
        title: { Text(DiaryStringKey.edit) },
        icon: { Image(hDiarySymbol: .edit) }
      )
    }
    .tint(.accentColor)
  }
}

private extension Moment {
  func getThumbnail() -> UIImage? {
    // New
    let firstMediaItem = mediaItems?.first(where: { $0.thumbnailData150px.map { data in UIImage(data: data) } != nil })
    let thumbnailFromNewSchema = firstMediaItem?.thumbnailData500px.flatMap { UIImage(data: $0) }

    // Legacy
    let firstLegacyHappyImage = images?.first(where: { $0.thumbnailData150px.map({ data in UIImage(data: data) }) != nil })
    let legacyImage = firstLegacyHappyImage?.thumbnailData150px.flatMap { UIImage(data: $0) }
    if let thumbnailFromNewSchema {
      if let legacyImage {
        return firstLegacyHappyImage.unsafelyUnwrapped.creationDate < firstMediaItem.unsafelyUnwrapped.createDate ? legacyImage : thumbnailFromNewSchema
      }
      else {
        return thumbnailFromNewSchema
      }
    }
    else {
      return legacyImage
    }
  }
}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview(traits: .modifier(SampleDataModifier())) { @MainActor in
    @Previewable @Query var moments: [Moment]
    @Previewable @Query var tags: [Tag]

    return NavigationStack {
      List(moments.prefix(2)) { moment in
        NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: true)) {
          MomentListItemView(moment: moment)
        }
      }
      .listStyle(.plain)
      .navigationTitle(Text(verbatim: "demo"))
    }
    .previewEnvironment()
    .onAppear {
      moments.first?.updateTitle("long longlonglonglonglonglong longlonglonglonglonglonglonglonglonglonglonglonglonglong")
      moments.first?.updateTags(Array(tags.prefix(2)))

      moments.dropFirst().first?.updateTags(Array(tags.prefix(2)))
    }
  }

#endif
