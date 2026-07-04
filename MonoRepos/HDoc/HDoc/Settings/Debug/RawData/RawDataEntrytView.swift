//
//  RawDataEntrytView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import SwiftUI

@MainActor
struct RawDataEntrytView: View {
  var body: some View {
    List(.constant(RawDataDestination.allCases)) { destination in
      cell(for: destination.wrappedValue)
    }
    .navigationTitle(Text(verbatim: "Raw Data"))
  }

  @ViewBuilder
  private func cell(for destination: RawDataDestination) -> some View {
    switch destination {
    case .list:
      EmptyView()

    case .medicalStaff:
      NavigationLink(value: HDocNavigationTarget.rawData(.medicalStaff)) {
        Text(HDocString.MedicalStaff.medicalStaff)
      }
    case .medicalSite:
      NavigationLink(value: HDocNavigationTarget.rawData(.medicalSite)) {
        Text(HDocString.MedicalSite.medicalSite)
      }

    case .record:
      NavigationLink(value: HDocNavigationTarget.rawData(.record)) {
        Text(HDocString.record)
      }

    case .symptom:
      NavigationLink(value: HDocNavigationTarget.rawData(.symptom)) {
        Text(HDocString.symptom)
      }

    case .patient:
      NavigationLink(value: HDocNavigationTarget.rawData(.patient)) {
        Text(HDocString.Patient.patient)
      }

    case .location:
      NavigationLink(value: HDocNavigationTarget.rawData(.location)) {
        Text(verbatim: "Location")
      }
    case .parkingLocation:
      NavigationLink(value: HDocNavigationTarget.rawData(.parkingLocation)) {
        Text(verbatim: "ParkingLocation")
      }
    }
  }
}

#if DEBUG
  #Preview { @MainActor in
    NavigationStack {
      RawDataEntrytView()

        .previewEnvironment()
    }
  }

#endif
