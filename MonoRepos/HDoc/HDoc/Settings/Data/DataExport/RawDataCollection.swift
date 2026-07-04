//
//  RawDataCollection.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/12.
//

import CoreTransferable
import Foundation
import HDocAppConstants
import HDocModel
import HFoundation
import SwiftData

struct RawDataCollection: Transferable {
  let modelContext: ModelContext

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .json, shouldAllowToOpenInPlace: false) { item in
      Log.data.info("exporting all data as file")
      let data = try await item.prepareData()
      let url = URL.makeTempUrl().appendingPathExtension("json")
      try data.write(to: url)
      return SentTransferredFile(url)
    }

    DataRepresentation(exportedContentType: .json, exporting: { item in
      Log.data.info("exporting all data as data")
      let data = try await item.prepareData()
      return data
    })
  }

  @MainActor
  func prepareData() throws -> Data {
    let symptoms = try modelContext.fetch(FetchDescriptor<Symptom>())
    let medicalStaffs = try modelContext.fetch(FetchDescriptor<MedicalStaff>())
    let records = try modelContext.fetch(FetchDescriptor<Record>())
    let medicalSites = try modelContext.fetch(FetchDescriptor<MedicalSite>())
    let patients = try modelContext.fetch(FetchDescriptor<Patient>())

    struct Model: Encodable {
      let symptoms: [Symptom]
      let medicalStaffs: [MedicalStaff]
      let records: [Record]
      let medicalSites: [MedicalSite]
      let patients: [Patient]
    }

    let model = Model(
      symptoms: symptoms,
      medicalStaffs: medicalStaffs,
      records: records,
      medicalSites: medicalSites,
      patients: patients
    )

    return try JSONEncoder().encode(model)
  }
}
