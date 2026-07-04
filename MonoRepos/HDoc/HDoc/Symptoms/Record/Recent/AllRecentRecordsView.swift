//
//  AllRecentRecordsView.swift
//  HDoc
//
//  Created by tigerguo on 2024/8/4.
//

import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct AllRecentRecordsView: View {
  @Query(sort: [SortDescriptor<Record>(\.startDate, order: .reverse)]) private var records: [Record]

  var body: some View {
    RecordListView(records: records, showSymptom: true)
      .scrollIndicatorsFlash(onAppear: true)
      .scrollIndicatorsFlash(trigger: records.count)
      .navigationTitle(Text(HDocString.Record.allRecords))
  }
}

#Preview { @MainActor in
  NavigationStack {
    AllRecentRecordsView()
  }
  .previewEnvironment()
}
