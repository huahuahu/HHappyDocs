//
//  HDiaryNavigatorModifier.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import Foundation
import HDocAppConstants
import HDocLocation
import HDocModel
import Observation
import SwiftUI
import UniformTypeIdentifiers

@MainActor @Observable
class AppRoute {
  var selectedTab: HDocTab = .home
  var homeNavigationStore = NavigationStore()
  var libraryNavigationStore = NavigationStore()
  var settingNavigationStore = NavigationStore()

  var currentStore: NavigationStore {
    switch selectedTab {
    case .home:
      homeNavigationStore
    case .library:
      libraryNavigationStore
    case .settings:
      settingNavigationStore
    }
  }
}

enum HDocTab: String, CaseIterable, Hashable {
  case home
  case library
  case settings
}

struct DocNavigatorModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .navigationDestination(for: HDocNavigationTarget.self) { target in
        target.getTargetView()
      }
  }
}

extension View {
  func hDocNavigator() -> some View {
    modifier(DocNavigatorModifier())
  }
}

enum HDocNavigationTarget: Hashable {
  case symptomRecords(for: Symptom)
  case allRecords
  case symptom(Symptom)
  case record(Record)
  case rawData(RawDataDestination)
  case libraryEntry(LibraryEntry)
  case medicalStaff(MedicalStaff, readOnly: Bool = false)
  case medicalSite(MedicalSite)
  case patient(Patient)
  case medicalSiteLocation(_ medicalSite: MedicalSite)
  case medicalSiteParkingLocation(_ medicalSite: MedicalSite)
  case cloudData(for: RawDataDestination)

  @MainActor @ViewBuilder
  func getTargetView() -> some View {
    switch self {
    case let .symptomRecords(for: symptom):
      SymptomRecordListView(symptom: symptom)
    case .allRecords:
      AllRecentRecordsView()
    case let .record(record: record):
      RecordView(record: record)
    case let .symptom(symptom: symptom):
      SymptomDetailView(symptom: symptom)
    case let .rawData(rawDataDestination):
      switch rawDataDestination {
      case .list:
        RawDataEntrytView()
      case .medicalStaff:
        RawModelDataView<MedicalStaff>()
      case .record:
        RawModelDataView<Record>()
      case .symptom:
        RawModelDataView<Symptom>()
      case .medicalSite:
        RawModelDataView<MedicalSite>()
      case .patient:
        RawModelDataView<Patient>()
      case .location:
        RawModelDataView<Location>()
      case .parkingLocation:
        RawModelDataView<ParkingLocation>()
      }

    case let .libraryEntry(libraryEntry):
      switch libraryEntry {
      case .medicalStaff:
        MedicalListView()
      case .medicalSite:
        MedicalSiteListView()
      case .patient:
        PatientListView()
      }

    case let .medicalStaff(medicalStaff, readOnly: readOnly):
      MedicalStaffView(medicalStaff: medicalStaff, readOnlyMode: readOnly)
    case let .medicalSite(medicalSite):
      MedicalSiteView(medicalSite: medicalSite)
    case let .patient(patient):
      PatientView(patient: patient)
    case .medicalSiteLocation(let medicalSite):
      HDocAddMedicalSiteLocationView(medicalSite: medicalSite)
    case .medicalSiteParkingLocation(let medicalSite):
      HDocAddMedicalSiteParkingLotView(medicalSite: medicalSite)
    case let .cloudData(for: rawDataDestination):
      switch rawDataDestination {
      case .list:
        CloudDataEntryScreen()
      case .medicalStaff:
        CloudDataDetailScreen<MedicalStaff>()
      case .medicalSite:
        CloudDataDetailScreen<MedicalSite>()
      case .record:
        CloudDataDetailScreen<Record>()
      case .symptom:
        CloudDataDetailScreen<Symptom>()
      case .patient:
        CloudDataDetailScreen<Patient>()
      case .location:
        CloudDataDetailScreen<Location>()
      case .parkingLocation:
        CloudDataDetailScreen<ParkingLocation>()
      }
    }
  }
}

enum RawDataDestination: CaseIterable, Identifiable, Hashable {
  var id: Self {
    self
  }

  case list
  case medicalStaff
  case medicalSite
  case record
  case symptom
  case patient
  case location
  case parkingLocation
}
