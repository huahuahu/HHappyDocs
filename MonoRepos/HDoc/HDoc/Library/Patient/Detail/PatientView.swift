//
//  PatientView.swift
//  HDoc
//
//  Created by tigerguo on 2024/5/8.
//

import HDocModel
import HDocSharedView
import SwiftData
import SwiftUI

@MainActor
struct PatientView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore
  @Bindable var patient: Patient
  @State private var showDeleteAlert = false

  var body: some View {
    Form {
      nameSection
      detailSection
      symptomsSection
      deleteSection
    }
    .navigationTitle(Text(HDocString.detail))
  }

  private var nameSection: some View {
    Section {
      TextField(text: $patient.name) {
        Text(HDocString.Common.name)
      }
    } header: {
      Text(HDocString.Common.name)
    }
  }

  private var detailSection: some View {
    Section {
      NavigationLink {
        SymptomDetailEditView(text: $patient.detail)
      } label: {
        Text(patient.detail.removeEmptyLines())
          .lineLimit(3)
          .truncationMode(.tail)
      }
    } header: {
      Text(HDocString.detail)
    }
  }

  private var symptomsSection: some View {
    SymptomSection(patient: patient)
  }

  private var deleteSection: some View {
    Section {
      Button(role: .destructive) {
        showDeleteAlert = true
      } label: {
        Text(HDocString.Common.delete)
          .foregroundStyle(.primary)
      }
      .alert(Text(HDocString.Patient.deleteMessage), isPresented: $showDeleteAlert) {
        Button(role: .destructive) {
          deletePatient()
        } label: {
          Text(HDocString.Common.delete)
        }

        Button(role: .cancel, action: {}, label: {
          Text(HDocString.Common.cancel)
        })
      }
    }
  }

  private func deletePatient() {
    if case let .patient(lastSite) = navigationStore.path.last,
       lastSite == patient {
      navigationStore.path.removeLast()
    }
    modelContext.delete(patient)
  }
}

#if DEBUG
  private struct PreviewContainerView: View {
    @Query private var patients: [Patient]
    var body: some View {
      PatientView(patient: patients[0])
    }
  }

  #Preview { @MainActor in
    NavigationStack {
      PreviewContainerView()
    }
    .previewEnvironment()
  }

#endif
