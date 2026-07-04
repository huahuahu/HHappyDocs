//
//  CloudDataEntryScreen.swift
//  HDoc
//
//  Created by tigerguo on 2024/9/21.
//

import HDocModel
import SwiftUI

@MainActor
struct CloudDataEntryScreen: View {
  var body: some View {
    List(RawDataDestination.allCases) { destination in
      cell(for: destination)
    }
    .navigationTitle(Text(HDocString.CloudData.cellLabel))
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private func cell(for destination: RawDataDestination) -> some View {
    switch destination {
    case .list:
      EmptyView()
    case .medicalStaff:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .medicalStaff)) {
        DataEntryCell<MedicalStaff>(recordType: HDocString.MedicalStaff.medicalStaff)
      }
    case .medicalSite:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .medicalSite)) {
        DataEntryCell<MedicalSite>(recordType: HDocString.MedicalSite.medicalSite)
      }

    case .record:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .record)) {
        DataEntryCell<Record>(recordType: HDocString.record)
      }

    case .symptom:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .symptom)) {
        DataEntryCell<Symptom>(recordType: HDocString.symptom)
      }

    case .patient:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .patient)) {
        DataEntryCell<Patient>(recordType: HDocString.Patient.patient)
      }

    case .location:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .location)) {
        DataEntryCell<Location>(recordType: HDocString.MedicalSite.location)
      }

    case .parkingLocation:
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .parkingLocation)) {
        DataEntryCell<ParkingLocation>(recordType: HDocString.MedicalSite.parkingLocation)
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    CloudDataEntryScreen()
  }
  .previewEnvironment()
}
