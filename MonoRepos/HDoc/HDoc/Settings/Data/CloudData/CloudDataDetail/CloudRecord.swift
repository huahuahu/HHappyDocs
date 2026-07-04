//
//  CloudRecord 2.swift
//  HDoc
//
//  Created by tigerguo on 2024/9/22.
//
import Foundation
import HDocModel

protocol CloudRecord {
  static var recordType: String { get }
  /// text shown to user about what's the record's name
  static var userDisplayTitle: LocalizedStringResource { get }
  static var nameFieldInCloud: String { get }
}

extension MedicalSite: CloudRecord {
  static var recordType: String { "CD_MedicalSite" }

  static var userDisplayTitle: LocalizedStringResource {
    HDocString.MedicalSite.medicalSite
  }

  static var nameFieldInCloud: String {
    "CD_name"
  }
}

extension Symptom: CloudRecord {
  static var recordType: String { "CD_Symptom" }
  static var userDisplayTitle: LocalizedStringResource {
    HDocString.symptom
  }

  static var nameFieldInCloud: String {
    "CD_title"
  }
}

extension Record: CloudRecord {
  static var recordType: String { "CD_Record" }
  static var userDisplayTitle: LocalizedStringResource {
    HDocString.record
  }

  static var nameFieldInCloud: String {
    "CD_title"
  }
}

extension MedicalStaff: CloudRecord {
  static var recordType: String { "CD_MedicalStaff" }
  static var userDisplayTitle: LocalizedStringResource {
    HDocString.MedicalStaff.medicalStaff
  }

  static var nameFieldInCloud: String {
    "CD_name"
  }
}

extension Patient: CloudRecord {
  static var recordType: String { "CD_Patient" }
  static var userDisplayTitle: LocalizedStringResource {
    HDocString.Patient.patient
  }

  static var nameFieldInCloud: String {
    "CD_name"
  }
}

extension Location: CloudRecord {
  static var recordType: String { "CD_Location" }
  static var userDisplayTitle: LocalizedStringResource {
    HDocString.MedicalSite.location
  }

  static var nameFieldInCloud: String {
    "CD_name"
  }
}

extension ParkingLocation: CloudRecord {
  static var recordType: String { "CD_ParkingLocation" }
  static var userDisplayTitle: LocalizedStringResource {
    HDocString.MedicalSite.parkingLocation
  }

  static var nameFieldInCloud: String {
    "CD_name"
  }
}
