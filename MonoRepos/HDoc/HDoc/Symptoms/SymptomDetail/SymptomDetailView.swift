//
//  SymptomDetailView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import HDocAppConstants
import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct SymptomDetailView: View {
  @Environment(NavigationStore.self) private var navigationStore
  @Environment(\.modelContext) private var modelContext
  @Bindable var symptom: Symptom
  @State private var showDeleteAlert = false

  @Query(sort: [SortDescriptor<Patient>(\.name, order: .forward)]) private var patients: [Patient]

  var body: some View {
    Form {
      patientView
      titleSection
      startDateSection
      detailSection
      SymptomRecordsSection(symptom: symptom)
      deleteSection
    }
    .navigationTitle(Text(HDocString.symptom))
  }

  private var patientView: some View {
    Picker(selection: $symptom.patient) {
      Text(HDocString.Patient.unknown)
        .tag(Patient?.none)
      ForEach(patients) { patient in
        Text(patient.name)
          .tag(Optional(patient))
      }
    } label: {
      Text(HDocString.Patient.patient)
    }
  }

  private var titleSection: some View {
    Section {
      TextField(text: $symptom.title) {
        Text(HDocString.title)
      }
    } header: {
      Text(HDocString.title)
    }
  }

  private var startDateSection: some View {
    Section {
      DatePicker(selection: $symptom.startDate) {
        Image(hdocSymbol: .calendar)
          .foregroundColor(.accentColor)
          .font(.title2)
      }
    } header: {
      Text(HDocString.Common.startDate)
    }
  }

  private var detailSection: some View {
    Section {
      NavigationLink {
        SymptomDetailEditView(text: $symptom.detail)
      } label: {
        Text(symptom.detail.removeEmptyLines())
          .lineLimit(3)
          .truncationMode(.tail)
      }
    } header: {
      Text(HDocString.detail)
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
      .alert(Text(HDocString.Symptom.deleteMessage), isPresented: $showDeleteAlert) {
        Button(role: .destructive) {
          deleteSymptom()
        } label: {
          Text(HDocString.Common.delete)
        }

        Button(role: .cancel, action: {}, label: {
          Text(HDocString.Common.cancel)
        })
      }
    }
  }

  private func deleteSymptom() {
    if case let .symptom(lastSymptom) = navigationStore.path.last,
       lastSymptom == symptom {
      navigationStore.path.removeLast()
    }
    modelContext.delete(symptom)
  }
}

private struct PreviewContainerView: View {
  var body: some View {
    SymptomDetailView(symptom: SampleData.symptoms[0])
  }
}

#Preview("cn") {
  NavigationStack {
    PreviewContainerView()
      .previewEnvironment()
  }
  .environment(\.locale, .cnMainland)
}

#Preview("en") {
  NavigationStack {
    PreviewContainerView()
      .previewEnvironment()
  }
  .environment(\.locale, .en)
}
