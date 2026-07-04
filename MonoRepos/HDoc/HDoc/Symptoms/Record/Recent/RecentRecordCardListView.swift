//
//  RecentRecordCardListView.swift
//  HDoc
//
//  Created by tigerguo on 2024/8/3.
//

import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct RecentRecordCardListView: View {
  @Query(sort: [SortDescriptor<Record>(\.startDate, order: .reverse)]) private var records: [Record]

  @ScaledMetric private var listRowInset = 5.0

  var body: some View {
    if records.isEmpty {
      EmptyView()
    }
    else {
      Section {
        ScrollView(.horizontal) {
          HStack(alignment: .top, content: {
            ForEach(records.prefix(4)) { record in
              NavigationLink(value: HDocNavigationTarget.record(record)) {
                RecentRecordCell(record: record)
              }
            }
            NavigationLink(value: HDocNavigationTarget.allRecords) {
              AllRecordsCell()
              Spacer()
            }
          })
          .fixedSize(horizontal: false, vertical: true)
        }
        .scrollIndicators(.hidden, axes: .horizontal)
        .listRowInsets(.some(.init(top: listRowInset, leading: listRowInset, bottom: listRowInset, trailing: listRowInset)))
      } header: {
        Text(HDocString.Record.recent)
      }
    }
  }
}

@MainActor private struct AllRecordsCell: View {
  var body: some View {
    GroupBox {
      Label(
        title: { Text(HDocString.Record.allRecords) },
        icon: { Image(systemName: "list.bullet") }
      )
    }
  }
}

@MainActor private struct RecentRecordCell: View {
  let record: Record

  @ScaledMetric private var maxWidth = 150.0
  @ScaledMetric private var titleVerticalPadding = 10.0

  var body: some View {
    GroupBox(
      label: Text(record.startDate, style: .relative)
        .font(.footnote),
      content: {
        HStack(content: {
          VStack(alignment: .leading) {
            Text(record.title)
              .font(.body)
              .lineLimit(2, reservesSpace: true)
              .multilineTextAlignment(.leading)
              .padding(.bottom, titleVerticalPadding)

            Text(record.symptom?.patient?.name ?? "")
              .font(.footnote)
          }

          Spacer()
        })
      }
    )
    .frame(width: maxWidth)
  }
}

#Preview { @MainActor in
  NavigationStack(root: {
    SymptomListView(sortOrder: .title)

      .navigationDestination(for: HDocNavigationTarget.self, destination: { target in
        target.getTargetView()
      })
      .navigationTitle(Text(verbatim: "Home"))
  })
  .previewEnvironment()
}

#Preview("record", body: { @MainActor in
  guard let record = try? HDocContainer.previewContainer.mainContext.fetch(FetchDescriptor<Record>()).first else {
    return EmptyView()
  }
  record.title = "long long long long"
  record.startDate = Date().addingTimeInterval(-3600)
  record.symptom = Symptom(title: "test symptom", detail: "test detal")
  record.symptom?.patient = Patient(name: "J.D Gld")
//    record.startDate =

  return NavigationStack {
    VStack {
      ScrollView(.horizontal) {
        HStack {
          RecentRecordCell(record: record).previewEnvironment()
        }
      }
    }
  }
})
