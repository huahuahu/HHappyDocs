//
//  Container.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation
import HDocModel
import SwiftData

extension HDocContainer {
  @MainActor static let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
      container = try ModelContainer(for: Symptom.self, configurations: config)
    }
    catch {
      fatalError("Can't create container with error \(error)")
    }

    for record in SampleData.records {
      container.mainContext.insert(record)
    }

    for symptom in SampleData.symptoms {
      container.mainContext.insert(symptom)
    }

    for item in SampleData.medicalStaff {
      container.mainContext.insert(item)
    }

    for medicalSite in SampleData.medicalSites {
      container.mainContext.insert(medicalSite)
    }

    for patient in SampleData.patients {
      container.mainContext.insert(patient)
    }

    for record in SampleData.records {
      record.symptom = SampleData.symptoms.randomElement()
    }

    for patient in SampleData.patients {
      patient.symptoms = SampleData.symptoms
    }

    return container
  }()
}

enum SampleData {
  static let symptoms = [
    Symptom(title: "cold", detail: "感冒了\n感冒了\n感冒了\n感冒了\n"),
    Symptom(title: "Covid", detail: "新冠"),
    Symptom(title: "牙周炎", detail: "牙疼"),
  ]

  static let records = [
    Record(title: "初诊", detail: "做检查，拿了药"),
    Record(title: "复查", detail: "做检查，基本没问题了"),
  ]

  static let medicalStaff = [
    MedicalStaff(name: "钱惠", detail: "主治医师"),
    MedicalStaff(name: "王胜", detail: "Dr. John Smith is a highly experienced and dedicated medical professional with over 20 years of experience ."),
  ]

  static let medicalSites = [
    MedicalSite(name: "红房子医院"),
    MedicalSite(name: "独墅湖医院"),
  ]

  static let patients = [
    Patient(name: "我自己"),
    Patient(name: "老婆"),
  ]
}
