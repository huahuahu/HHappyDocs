//
//  PatientSymptomView.swift
//  HDoc
//
//  Created by tigerguo on 2025/5/11.
//

import HDocAppConstants
import HDocModel
import SwiftData
import SwiftUI

extension PatientView {
  @MainActor
  struct SymptomSection: View {
    let patient: Patient
    @State private var sortOrder: SortOrder = .byCreationDate
    @Query private var symptoms: [Symptom]
    @Query private var records: [Record]
    @Environment(\.modelContext) private var modelContext
    @State private var contentType: ContentType = .record

    fileprivate enum ContentType: Hashable, Identifiable, CaseIterable {
      case symptom
      case record

      var id: Self {
        self
      }

      var labelInPicker: LocalizedStringResource {
        switch self {
        case .symptom:
          HDocString.symptom
        case .record:
          HDocString.record
        }
      }
    }

    fileprivate enum SortOrder: Hashable, Identifiable, CaseIterable {
      case byCreationDate
      case byTitle

      var id: Self { self }

      var labelInPicker: LocalizedStringResource {
        switch self {
        case .byTitle:
          HDocString.Common.sortByTitle
        case .byCreationDate:
          HDocString.Common.sortByStartDate
        }
      }
    }

    init(patient: Patient) {
      self.patient = patient
      let patientID = patient.id
      let predicate = #Predicate<Symptom> { symptom in
        return symptom.patient?.persistentModelID == patientID
      }
      _symptoms = Query(filter: predicate)
      _records = Query(filter: #Predicate<Record> { record in
        record.symptom?.patient?.persistentModelID == patientID
      })
    }

    var body: some View {
      Section {
        contentPicker
        switch contentType {
        case .symptom:
          symptomView
        case .record:
          recordView
        }
      } header: {
        HStack {
          Spacer()
          SymptomSortView(sortOrder: $sortOrder)
        }
      }
    }

    @ViewBuilder
    private var contentPicker: some View {
      Picker(selection: $contentType) {
        ForEach(Self.ContentType.allCases) { contentType in
          Text(contentType.labelInPicker)
            .tag(contentType)
        }
      } label: {
        EmptyView()
      }
      .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var symptomView: some View {
      if symptoms.isEmpty {
        ContentUnavailableView(
          String(
            localized: HDocString.Symptom.noSymptomMessage
          ),
          systemImage: HDocSymbol.circle.rawValue
        )
      }
      else {
        ForEach(sortedSymptoms) { symptom in
          NavigationLink(value: HDocNavigationTarget.symptom(symptom)) {
            SymptomListView.SymptomCellView(symptom: symptom, config: .init(showPatient: false))
          }
        }
      }
    }

    private var sortedSymptoms: [Symptom] {
      switch sortOrder {
      case .byCreationDate:
        return symptoms.sorted { $0.creationDate > $1.creationDate }
      case .byTitle:
        return symptoms.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
      }
    }

    @ViewBuilder
    private var recordView: some View {
      if sortedRecords.isEmpty {
        ContentUnavailableView(
          String(
            localized: HDocString.Record.noRecordMessage
          ),
          systemImage: HDocSymbol.circle.rawValue
        )
      }
      else {
        ForEach(sortedRecords) { record in
          NavigationLink(value: HDocNavigationTarget.record(record)) {
            RecordListView.RecordCell(record: record, showSymptom: true)
          }
        }
      }
    }

    private var sortedRecords: [Record] {
      let allRecords: [Record] = symptoms.flatMap { $0.records ?? [] }
      switch sortOrder {
      case .byCreationDate:
        return allRecords.sorted { $0.startDate > $1.startDate }
      case .byTitle:
        return allRecords.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
      }
    }
  }

  private struct SymptomSortView: View {
    @Binding var sortOrder: SymptomSection.SortOrder
    var body: some View {
      Picker(selection: $sortOrder) {
        ForEach(SymptomSection.SortOrder.allCases) { sortOrder in
          Text(sortOrder.labelInPicker)
            .tag(sortOrder)
        }
      } label: {
        Label(
          title: { Text(HDocString.Common.sort) },
          icon: { Image(hdocSymbol: .sort) }
        )
      }
    }
  }
}

@available(iOS 18, *)
#Preview(traits: .modifier(SampleDataModifier())) {
  @Previewable @Query var patients: [Patient]
  let patient = patients.first(where: { $0.symptoms?.isEmpty == false })!
  NavigationStack {
    PatientView(patient: patient)
  }
}
