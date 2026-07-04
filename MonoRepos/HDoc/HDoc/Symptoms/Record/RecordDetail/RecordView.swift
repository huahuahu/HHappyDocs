//
//  RecordView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/30.
//

import HDocAppConstants
import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct RecordView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore

  @State private var showDeleteAlert = false
  @Bindable var record: Record
  var body: some View {
    Form {
      titleSection
      detailSection
      dateSection
      symptomSection
      RecordMedicalStaffSection(record: record)
      MedicalSiteSection(record: record)
      deleteSection
    }
    .navigationTitle(Text(HDocString.record))
  }

  private var titleSection: some View {
    Section {
      TextField(text: $record.title, prompt: Text(HDocString.title)) {
        Text(HDocString.title)
      }
    } header: {
      Text(HDocString.title)
    }
  }

  private var detailSection: some View {
    Section {
      NavigationLink {
        SymptomDetailEditView(text: $record.detail)
      } label: {
        Text(record.detail.removeEmptyLines())
          .lineLimit(3)
          .truncationMode(.tail)
      }
    } header: {
      Text(HDocString.detail)
    }
  }

  private var dateSection: some View {
    Section {
      DatePicker(selection: $record.startDate) {
        Text(HDocString.Common.startDate)
      }
      DatePicker(selection: .init(get: {
        record.endDate ?? Date()
      }, set: { date in
        record.endDate = date
      }), in: record.startDate...) {
        Text(HDocString.Common.endDate)
      }
    }
  }

  @ViewBuilder
  private var symptomSection: some View {
    if let symptom = record.symptom {
      NavigationLink(value: HDocNavigationTarget.symptom(symptom)) {
        LabeledContent {
          Text(symptom.title)
        } label: {
          Text(HDocString.symptom)
        }
      }
    }
    else {
      EmptyView()
    }
  }

  private var deleteSection: some View {
    Section {
      Button(role: .destructive) {
        showDeleteAlert = true
      } label: {
        Text(HDocString.Common.delete)
          .foregroundStyle(.primary)
      }
      .alert(Text(HDocString.Record.deleteMessage), isPresented: $showDeleteAlert) {
        Button(role: .destructive) {
          if case let .record(lastRecord) = navigationStore.path.last,
             lastRecord == record {
            navigationStore.path.removeLast()
          }
          modelContext.delete(record)
        } label: {
          Text(HDocString.Common.delete)
        }
        Button(role: .cancel, action: {}, label: {
          Text(HDocString.Common.cancel)
        })
      }
    }
  }
}

#if DEBUG
  private struct PreviewContainerView: View {
    @Query private var records: [Record]
    var body: some View {
      RecordView(record: records[0])
    }
  }

  #Preview { @MainActor in
    NavigationStack {
      PreviewContainerView()
    }
    .previewEnvironment()
  }
#endif
