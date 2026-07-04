//
//  SymptomRecordListView.swift
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
struct SymptomRecordListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore
  @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus
  @Environment(UserPreferences.self) private var userPreferences

  @Bindable var symptom: Symptom
  @Query(sort: [SortDescriptor<Record>(\.startDate, order: .reverse)]) private var records: [Record]

  @State private var presentRecordSubscriptionView = false
  @State private var presentRecordSubscriptionPromotionView = false
  var body: some View {
    RecordListView(records: recordsForSymptom, showSymptom: false)
      .toolbar { toolbarContent }
      .navigationTitle(Text(HDocString.Symptom.allRecords))
      .scrollIndicatorsFlash(onAppear: true)
      .scrollIndicatorsFlash(trigger: records.count)
      .overlay {
        if recordsForSymptom.isEmpty {
          noRecordView
        }
      }
  }

  private var recordsForSymptom: [Record] {
    records.filter { record in
      record.symptom?.id == symptom.id
    }
  }

//  private func deleteRecord(at indexSet: IndexSet) {
//    let recordsForSymptom = recordsForSymptom
//    indexSet.forEach { index in
//      let record = recordsForSymptom[index]
//      modelContext.delete(record)
//    }
//  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(action: {
        addRecord()
      }, label: {
        Label(
          title: { Text(HDocString.add) },
          icon: { Image(hdocSymbol: .plus) }
        )
        .labelStyle(.iconOnly)
      })
      .sheet(isPresented: $presentRecordSubscriptionView) {
        RecordSubscriptionView()
      }
      .sheet(isPresented: $presentRecordSubscriptionPromotionView) {
        RecordSubscriptionPromotionView {
          addRecord()
        }
      }
    }
  }

  private func addRecord() {
    if userPreferences.hasPromotedRecordSubscription {
      if case .notSubscribed = recordSubscriptionStatus, records.count >= AppConstants.IAP.freeRecordNumber {
        presentRecordSubscriptionView = true
        Log.iap.info("Show need subscribe record view from record list")
      }
      else {
        Log.data.log("add record for \(String(describing: symptom.uuid)) in record list")
        let record = Record(title: "", detail: "")
//        symptom.records?.append(record)
        record.symptom = symptom
        modelContext.insert(record)
        navigationStore.path.append(HDocNavigationTarget.record(record))
      }
    }
    else {
      Log.iap.info("Show RecordSubscriptionPromotionView from record list")
      presentRecordSubscriptionPromotionView = true
    }
  }

  private var noRecordView: some View {
    ContentUnavailableView(
      String(
        localized: HDocString.Record.noRecordMessage
      ),
      systemImage: HDocSymbol.circle.rawValue
    )
  }
}

#if DEBUG
  private struct PreviewContainerView: View {
    @Query var symptoms: [Symptom]
    var body: some View {
      SymptomRecordListView(symptom: symptoms[0])
        .onAppear {
          for record in SampleData.records {
            symptoms[0].records?.append(record)
          }
        }
    }
  }

  #Preview { @MainActor in
    NavigationStack {
      PreviewContainerView()
    }
    .previewEnvironment()
  }

#endif
