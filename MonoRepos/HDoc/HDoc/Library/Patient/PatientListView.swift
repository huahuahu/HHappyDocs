//
//  PatientListView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocAppConstants
import HDocModel
import HFoundation
import SwiftData
import SwiftUI

@MainActor
struct PatientListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore

  var body: some View {
    ListView()
      .toolbar {
        toolbarView
      }
      .navigationTitle(Text(HDocString.Patient.patient))
  }

  @ToolbarContentBuilder
  private var toolbarView: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: {
        addStaff()
      }, label: {
        Label(
          title: { Text(HDocString.add) },
          icon: { Image(hdocSymbol: .plus) }
        )
      })
    }
  }

  private func addStaff() {
    let patient = Patient(name: "")
    modelContext.insert(patient)
    navigationStore.path.append(.patient(patient))
  }
}

@MainActor
private extension PatientListView {
  struct ListView: View {
    @Query(sort: [SortDescriptor(\Patient.name, order: .forward)]) private var patients: [Patient]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
      List {
        ForEach(patients) { patient in
          NavigationLink(value: HDocNavigationTarget.patient(patient)) {
            Text(patient.name)
          }
        }
//        .onDelete {
//          deleteSite(at: $0)
//        }
      }
      .overlay {
        if patients.isEmpty {
          emptyView
        }
      }
      .scrollIndicatorsFlash(onAppear: true)
      .scrollIndicatorsFlash(trigger: patients.count)
    }

    private var emptyView: some View {
      ContentUnavailableView(
        String(
          localized: HDocString.Patient.noPatientMessage
        ),
        systemImage: HDocSymbol.circle.rawValue
      )
    }

//    private func deleteSite(at indexSet: IndexSet) {
//      let medicalSitesToDelete = indexSet.map {
//        medicalSites[$0]
//      }
//
//      medicalSitesToDelete.forEach {
//        modelContext.delete($0)
//      }
//    }
  }
}

#if DEBUG
  #Preview("non-empty") { @MainActor in
    NavigationStack {
      PatientListView()
        .hDocNavigator()
    }
    .previewEnvironment()
  }

  #Preview("empty") { @MainActor in
    NavigationStack {
      PatientListView()
    }
    .previewEnvironment()
    .environment(\.locale, .cnMainland)
    .onAppear {
      try? HDocContainer.previewContainer.mainContext.delete(model: Patient.self)
    }
  }

#endif
