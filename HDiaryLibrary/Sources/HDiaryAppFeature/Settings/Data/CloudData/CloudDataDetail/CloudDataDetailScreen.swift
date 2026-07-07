//
//  RawModelDataView.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/29.
//
#if os(iOS)

import HDiaryModel
import SwiftData
import SwiftUI

@MainActor
struct CloudDataDetailScreen<T: CloudRecord>: View {
  @State private var model = CloudDataModel<T>()

  var body: some View {
    content
      .toolbar {
        toolBarContent
      }
      .navigationTitle(Text(T.userDisplayTitle))
      .task {
        if model.state.isIdle {
          await model.refresh()
        }
      }
  }

  @ViewBuilder
  private var content: some View {
    switch model.state {
    case .idle:
      Text(verbatim: "")
    case .loading:
      ProgressView {
        Text(DiaryStringKey.Data.CloudData.syncing)
      }
    case .error(let err):
      ScrollView {
        Text(err.localizedDescription)
      }
    case .loaded(let recordResults, cursor: let cursor, let error):
      let footerState: EntryListFooterView.FooterState = {
        if error != nil {
          return .fetchMoreFail
        }
        else if cursor != nil {
          return .hasMore
        }
        else {
          return .allLoaded
        }
      }()
      entryList(for: recordResults, footerState: footerState)

    case .continueLoading(previousResult: let recordResults):
      entryList(for: recordResults, footerState: .loading)
    }
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      RefreshButton {
        Task {
          await model.refresh()
        }
      }
      .disabled(model.state.isLoading)
    }
  }

  private func entryList(for recordResults: [CloudDataModel<T>.RecordResult], footerState: EntryListFooterView.FooterState) -> some View {
    List {
      Section {
        ForEach(recordResults) {
          recordResult in
          switch recordResult {
          case .failure(let err, uuid: _):
            Text(err.localizedDescription)
              .font(.footnote)
              .foregroundStyle(.red)
          case let .loaded(record: record, name: name):
            RecordCell(name: name, modifiedDate: record.modificationDate)
          }
        }
      } footer: {
        EntryListFooterView(footerState: footerState) {
          Task {
            await model.continueFetch()
          }
        }
      }
    }
  }
}

@MainActor
private struct EntryListFooterView: View {
  @ScaledMetric private var paddingBetweenText = 1.0
  enum FooterState {
    case loading
    case hasMore
    case allLoaded
    case fetchMoreFail
  }

  let footerState: FooterState
  let loadMoreAction: () -> Void

  var body: some View {
    switch footerState {
    case .loading:
      Text(DiaryStringKey.Data.CloudData.syncing)
    case .allLoaded:
      Text(DiaryStringKey.Data.CloudData.allContent)
    case .hasMore:
      Button {
        loadMoreAction()
      } label: {
        Text(DiaryStringKey.Data.CloudData.loadMore)
      }
    case .fetchMoreFail:
      Button {
        loadMoreAction()
      } label: {
        Text(DiaryStringKey.Data.CloudData.loadFail)
      }
    }
  }
}

@MainActor
private struct RecordCell: View {
  @ScaledMetric private var paddingBetweenText = 1.0

  let name: String
  let modifiedDate: Date?

  var body: some View {
    VStack(alignment: .leading) {
      Text(name)
        .foregroundStyle(.primary)
        .bold()

      HStack {
        Text(DiaryStringKey.Data.CloudData.lastUpdateTime)
          .bold()
        if let modifiedDate {
          Text(modifiedDate.formatted(date: .numeric, time: .standard))
        }
        else {
          Text(DiaryStringKey.Data.CloudData.noData)
        }
      }
      .foregroundStyle(.secondary)
      .font(.footnote)
      .padding(.top, paddingBetweenText)
    }
  }
}

@MainActor
private struct RefreshButton: View {
  let onTap: () -> Void
  var body: some View {
    Button {
      onTap()
    } label: {
      Label {
        Text(verbatim: "refresh")
      } icon: {
        Image(hDiarySymbol: .refresh)
      }
      .labelStyle(.iconOnly)
    }
  }
}

#Preview { @MainActor in

  NavigationStack {
    CloudDataDetailScreen<Moment>()
  }
  .previewEnvironment()
}

#Preview("refresh button") { @MainActor in
  NavigationStack {
    Text(verbatim: "dd")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          RefreshButton {}
        }
      }
  }
  .previewEnvironment()
}

#Preview("RecordCell") { @MainActor in
  NavigationStack {
    List {
      RecordCell(name: "李欣", modifiedDate: Date.now)
    }
  }
  .previewEnvironment()
}

#Preview("RecordsFotter") { @MainActor in
  NavigationStack {
    List {
      Section {
        RecordCell(name: "allLoaded", modifiedDate: Date.now)
      } footer: {
        EntryListFooterView(footerState: .allLoaded) {}
      }

      Section {
        RecordCell(name: "fetchMoreFail", modifiedDate: Date.now)
      } footer: {
        EntryListFooterView(footerState: .fetchMoreFail) {}
      }

      Section {
        RecordCell(name: "loading", modifiedDate: Date.now)
      } footer: {
        EntryListFooterView(footerState: .loading) {}
      }

      Section {
        RecordCell(name: "hasMore", modifiedDate: Date.now)
      } footer: {
        EntryListFooterView(footerState: .hasMore) {}
      }
    }
  }
  .previewEnvironment()
}

#endif
