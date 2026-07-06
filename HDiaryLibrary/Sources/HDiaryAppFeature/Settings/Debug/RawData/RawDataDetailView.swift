//
//  RawDataDetailView.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/3.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

@MainActor
struct RawDataDetailView<T: RawData>: View {
  @Environment(\.modelContext) private var modelContext
  @State private var rawData: [T] = []
  @State private var sortOrder: RawDataSortOrder = .createDate

  var body: some View {
    List {
      ForEach(rawData) { item in
        NavigationLink {
          RawDataItemView(item: item)
        } label: {
          cell(for: item, with: sortOrder)
        }
      }
    }
    .toolbar {
      toolBarContent
    }
    .task {
      loadData()
    }
    .onChange(of: sortOrder, { _, _ in
      loadData()
    })
    .navigationTitle(String(describing: (T.self)))
  }

  @ViewBuilder
  private func cell(for item: T, with sortOrder: RawDataSortOrder) -> some View {
    switch sortOrder {
    case .createDate:
      VStack(alignment: .leading) {
        Text(item.creationDate, style: .date)
          .foregroundStyle(.secondary)
          .font(.caption)
          .padding(5)
          .background(Color.accentColor.opacity(0.3), in: RoundedRectangle(cornerRadius: 5))

        Text(item.debugInfoLabel)
          .foregroundStyle(.primary)
      }
    case .title:
      Text(item.debugInfoLabel)
        .foregroundStyle(.primary)

    case .size:
      VStack(alignment: .leading, content: {
        if let size = item.size {
          Text(size.formatted(.byteCount(style: .file)))
            .foregroundStyle(.secondary)
            .font(.caption)
            .padding(5)
            .background(Color.accentColor.opacity(0.3), in: RoundedRectangle(cornerRadius: 5))
        }
        Text(item.debugInfoLabel)
          .foregroundStyle(.primary)

      })
    }
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Menu {
        Picker(selection: $sortOrder) {
          ForEach(T.supportedSortType) { order in
            Text(String(describing: order))
              .tag(order)
          }
        } label: {
          Text(verbatim: "Select order")
        }
      } label: {
        Label(
          title: { Text(verbatim: "Sort by") },
          icon: { Image(hDiarySymbol: .sort) }
        )
      }
    }
  }

  private func loadData() {
    do {
      let items = try modelContext.fetch(FetchDescriptor<T>())
      rawData = items.sorted {
        return $0.compare(with: $1, by: sortOrder) == .orderedAscending
      }
    }
    catch {
      Log.data.error("Failed to fetch data: \(error)")
    }
  }
}

enum RawDataSortOrder: CaseIterable, Identifiable {
  var id: Self {
    self
  }

  case createDate
  case title
  case size
}

#Preview { @MainActor in
  NavigationStack {
    RawDataDetailView<Moment>()
  }
  .previewEnvironment()
}

#endif
