//
//  MedicalStaffView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocModel
import HDocSharedView
import SwiftData
import SwiftUI

@MainActor
struct MedicalStaffView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore
  @Bindable var medicalStaff: MedicalStaff
  @State private var showDeleteAlert = false
  let readOnlyMode: Bool

  init(medicalStaff: MedicalStaff, readOnlyMode: Bool) {
    self.medicalStaff = medicalStaff

    self.readOnlyMode = readOnlyMode
  }

  var body: some View {
    Form {
      nameSection
      detailSection
      siteSection
      if readOnlyMode == false {
        deleteSection
      }
    }
    .navigationTitle(Text(HDocString.detail))
  }

  private var nameSection: some View {
    Section {
      if readOnlyMode {
        Text(medicalStaff.name)
      }
      else {
        TextField(text: $medicalStaff.name) {
          Text(HDocString.Common.name)
        }
      }
    } header: {
      Text(HDocString.Common.name)
    }
  }

  private var detailSection: some View {
    Section {
      if readOnlyMode {
        Text(medicalStaff.detail.removeEmptyLines())
          .lineLimit(nil)
      }
      else {
        NavigationLink {
          SymptomDetailEditView(text: $medicalStaff.detail)
        } label: {
          Text(medicalStaff.detail.removeEmptyLines())
            .lineLimit(3)
            .truncationMode(.tail)
        }
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
      .alert(Text(HDocString.MedicalStaff.deleteMessage), isPresented: $showDeleteAlert) {
        Button(role: .destructive) {
          deleteStaff()
        } label: {
          Text(HDocString.Common.delete)
        }

        Button(role: .cancel, action: {}, label: {
          Text(HDocString.Common.cancel)
        })
      }
    }
  }

  private var siteSection: some View {
    SiteSection(medicalStaff: medicalStaff, isEditable: !readOnlyMode)
  }

  private func deleteStaff() {
    if case let .medicalStaff(lastStaff, _) = navigationStore.path.last,
       lastStaff == medicalStaff {
      navigationStore.path.removeLast()
    }
    modelContext.delete(medicalStaff)
  }
}

#if DEBUG
  private struct PreviewContainerView: View {
    @Query private var medicalStaffs: [MedicalStaff]
    var body: some View {
      MedicalStaffView(medicalStaff: medicalStaffs[0], readOnlyMode: true)
    }
  }

  #Preview { @MainActor in
    NavigationStack {
      PreviewContainerView()
    }
    .previewEnvironment()
  }

#endif
