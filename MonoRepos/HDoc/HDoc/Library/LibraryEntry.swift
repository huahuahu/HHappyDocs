//
//  LibraryEntry.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import Foundation
import HDocAppConstants

enum LibraryEntry: Identifiable, CaseIterable {
  case medicalStaff
  case medicalSite
  case patient

  var id: Self {
    self
  }

  var label: LocalizedStringResource {
    switch self {
    case .medicalStaff:
      HDocString.MedicalStaff.medicalStaff
    case .medicalSite:
      HDocString.MedicalSite.medicalSite
    case .patient:
      HDocString.Patient.patient
    }
  }

  var symbol: HDocSymbol {
    switch self {
    case .medicalStaff: .cross
    case .medicalSite: .medicalSite
    case .patient: .patient
    }
  }

  var desitination: HDocNavigationTarget {
    switch self {
    case .medicalStaff:
      HDocNavigationTarget.libraryEntry(.medicalStaff)
    case .medicalSite:
      HDocNavigationTarget.libraryEntry(.medicalSite)
    case .patient:
      HDocNavigationTarget.libraryEntry(.patient)
    }
  }
}
