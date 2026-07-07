//
//  RawDataView.swift
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
struct RawDataView: View {
  var body: some View {
    List(RawDataDestination.allCases) { rawData in
      NavigationLink(value: HDiaryDestination.rawData(destination: rawData)) {
        Cell(rawData: rawData)
      }
    }
    .navigationTitle(Text(verbatim: "Raw Data"))
  }

  private func fetchInfo() {
    do {}
  }
}

extension RawDataView {
  @MainActor private struct Cell: View {
    let rawData: RawDataDestination
    @State private var dataCount: Int?
    @Environment(\.modelContext) private var modelContext

    @ScaledMetric private var spacing: CGFloat = 8.0
    var body: some View {
      VStack(alignment: .leading, spacing: spacing) {
        Text(rawData.infoLabel)
          .foregroundStyle(.primary)
          .bold()
          .font(.headline)

        if let dataCount {
          Text(dataCount.formatted(.number))
            .foregroundStyle(.secondary)
            .font(.caption)
        }
      }
      .task {
        fetchData()
      }
    }

    private func fetchData() {
      do {
        switch rawData {
        case .moment:
          dataCount = try modelContext.fetchCount(FetchDescriptor<Moment>())
        case .participant:
          dataCount = try modelContext.fetchCount(FetchDescriptor<Participant>())
        case .tag:
          dataCount = try modelContext.fetchCount(FetchDescriptor<Tag>())
        case .mediaItem:
          dataCount = try modelContext.fetchCount(FetchDescriptor<MediaItem>())
        case .happyImage:
          dataCount = try modelContext.fetchCount(FetchDescriptor<HappyImage>())
        }
      }
      catch {
        Log.data.error("fetch raw data count \(rawData.infoLabel) fail")
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    RawDataView()
      .hDiaryNavigator()
  }
  .previewEnvironment()
}

#endif
