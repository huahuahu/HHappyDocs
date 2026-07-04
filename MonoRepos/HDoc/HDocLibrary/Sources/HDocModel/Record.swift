//
//  Record.swift
//
//
//  Created by tigerguo on 2023/12/29.
//
#if os(iOS)

  import Foundation
  import SwiftData

  @Model
  public class Record {
    public var title: String = ""
    public var detail: String = ""
    public var startDate: Date = Date()
    public var endDate: Date?
    public private(set) var creationDate: Date = Date.now
    public private(set) var uuid = UUID()
    public var symptom: Symptom?

    public var medicalStaffs: [MedicalStaff]? = []

    public var medicalSites: [MedicalSite]? = []

    public init(title: String, detail: String, startDate: Date = Date()) {
      self.startDate = startDate
      self.title = title
      self.detail = detail
      self.creationDate = .now
      self.uuid = UUID()
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(title, forKey: .title)
      try container.encode(detail, forKey: .detail)
      try container.encode(startDate, forKey: .startDate)
      try container.encode(endDate, forKey: .endDate)
      try container.encode(creationDate, forKey: .creationDate)
      try container.encode(uuid, forKey: .uuid)

      // Relationship
      try container.encode(symptom?.uuid, forKey: .symptom)
      try container.encode(medicalStaffs?.map { $0.uuid }, forKey: .medicalStaffs)
      try container.encode(medicalSites?.map { $0.uuid }, forKey: .medicalSites)
    }
  }

  extension Record: Encodable {
    enum CodingKeys: CodingKey {
      case title
      case detail
      case startDate
      case endDate
      case creationDate
      case uuid
      case symptom
      case medicalStaffs
      case medicalSites
    }
  }

#endif
