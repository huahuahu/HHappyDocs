//
//  SymptomRecordsSection.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/30.
//

import HDocAppConstants
import HDocIAP
import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct SymptomRecordsSection: View {
  @Bindable var symptom: Symptom
  @Environment(NavigationStore.self) private var navigationStore
  @Environment(\.modelContext) private var modelContext
  @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus
  @Environment(UserPreferences.self) private var userPreferences
  @Query private var records: [Record]

  @State private var presentRecordSubscriptionView = false
  @State private var presentRecordSubscriptionPromotionView = false
  @State private var recentRecordExpanded = true

  var body: some View {
    Section {
      addRecordCell
      allRecordsCell
      recentRecordsView
    } header: {
      Text(HDocString.record)
    }
  }

  @ViewBuilder
  private var addRecordCell: some View {
    Button(action: {
      addRecord()
    }, label: {
      Label(
        title: { Text(HDocString.Symptom.addRecord) },
        icon: { Image(hdocSymbol: .plus) }
      )
    })
    .alignmentGuide(.listRowSeparatorLeading) { _ in
      0
    }
    .sheet(isPresented: $presentRecordSubscriptionView) {
      RecordSubscriptionView()
    }
    .sheet(isPresented: $presentRecordSubscriptionPromotionView) {
      RecordSubscriptionPromotionView {
        addRecord()
      }
    }
  }

  @ViewBuilder
  private var recentRecordsView: some View {
    if !recordsForSymptom.isEmpty {
      DisclosureGroup(
        isExpanded: $recentRecordExpanded,
        content: {
          ForEach(recordsForSymptom.sorted { $0.startDate > $1.startDate }.prefix(3)) { record in
            NavigationLink(value: HDocNavigationTarget.record(record)) {
              RecentRecordCell(record: record)
            }
          }
        },
        label: { Text(HDocString.Symptom.recentRecords) }
      )
    }
  }

  private var recordsForSymptom: [Record] {
    return records.filter { record in
      record.symptom?.id == symptom.id
    }
  }

  @ViewBuilder
  private var allRecordsCell: some View {
    NavigationLink(value: HDocNavigationTarget.symptomRecords(for: symptom)) {
      Text(HDocString.Symptom.allRecords)
    }
  }

  private func addRecord() {
    if userPreferences.hasPromotedRecordSubscription {
      if case .notSubscribed = recordSubscriptionStatus, records.count >= AppConstants.IAP.freeRecordNumber {
        presentRecordSubscriptionView = true
        Log.iap.info("Show need subscribe record view from symptom add record cell")
      }
      else {
        Log.data.log("add record for \(String(describing: symptom.uuid)) in symptom detail")
        let record = Record(title: "", detail: "")
        record.symptom = symptom
        modelContext.insert(record)
        navigationStore.path.append(HDocNavigationTarget.record(record))
      }
    }
    else {
      Log.iap.info("Show RecordSubscriptionPromotionView from symptom add record cell")
      presentRecordSubscriptionPromotionView = true
    }
  }
}

extension SymptomRecordsSection {
  @MainActor
  struct RecentRecordCell: View {
    @ScaledMetric private var padding = 6.0

    let record: Record

    var body: some View {
      VStack(alignment: .leading, spacing: padding) {
        Text(record.startDate, style: .relative)
          .foregroundStyle(.secondary)
          .font(.caption)
        Text(record.title)
          .foregroundStyle(.primary)
          .font(.headline)
      }
    }
  }
}

#if DEBUG
  import HFoundation

  private struct PreviewContainerView: View {
    @Query private var symptoms: [Symptom]

    var body: some View {
      List {
        SymptomRecordsSection(symptom: symptoms[0])
      }
      .onAppear {
        symptoms[0].records?.append(SampleData.records[0])
      }
    }
  }

  #Preview {
    NavigationStack {
      PreviewContainerView()
        .previewEnvironment()
    }
  }

  #Preview("cn") {
    NavigationStack {
      PreviewContainerView()
        .previewEnvironment()
    }
    .environment(\.locale, .cnMainland)
  }

#endif
