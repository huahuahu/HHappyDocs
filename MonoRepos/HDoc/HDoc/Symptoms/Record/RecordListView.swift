//
//  RecordListView.swift
//  HDoc
//
//  Created by tigerguo on 2024/8/4.
//

import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct RecordListView: View {
  let records: [Record]
  let showSymptom: Bool
  var body: some View {
    List {
      ForEach(records) { record in
        NavigationLink(value: HDocNavigationTarget.record(record)) {
          RecordCell(record: record, showSymptom: showSymptom)
        }
      }
    }
  }
}

extension RecordListView {
  @MainActor
  struct RecordCell: View {
    @ScaledMetric private var padding = 6.0
    let record: Record
    let showSymptom: Bool

    var body: some View {
      VStack(alignment: .leading, spacing: padding) {
        HStack {
          Text(record.startDate, style: .date)
            .foregroundStyle(.secondary)
            .font(.caption)
          if showSymptom, let symptomTitle = record.symptom?.title {
            Text(symptomTitle)
              .foregroundStyle(.secondary)
              .font(.caption)
            Spacer()
          }
        }
        Text(record.title)
          .foregroundStyle(.primary)
          .font(.headline)
      }
    }
  }
}

private struct ContainerView: View {
  @Query(sort: [SortDescriptor<Record>(\.startDate, order: .reverse)]) private var records: [Record]
  var body: some View {
    RecordListView(records: records, showSymptom: true)
  }
}

#Preview { @MainActor in

  ContainerView()
    .previewEnvironment()
}
