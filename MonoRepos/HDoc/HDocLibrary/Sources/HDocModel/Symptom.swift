//
//  File.swift
//
//
//  Created by tigerguo on 2023/12/29.
//
#if os(iOS)

  import Foundation
  import SwiftData

  @Model
  public class Symptom {
    public var title: String = ""
    public var detail: String = ""
    public private(set) var creationDate: Date = Date.now
    public var startDate: Date = Date.now
    public private(set) var uuid = UUID()
    @Relationship(deleteRule: .cascade, inverse: \Record.symptom) public var records: [Record]? = []
    public var patient: Patient?

    public init(
      title: String,
      detail: String,
      startDate: Date = .now
    ) {
      self.title = title
      self.detail = detail
      self.creationDate = .now
      self.uuid = uuid
      self.startDate = startDate
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(title, forKey: .title)
      try container.encode(detail, forKey: .detail)
      try container.encode(creationDate, forKey: .creationDate)
      try container.encode(startDate, forKey: .startDate)
      try container.encode(uuid, forKey: .uuid)

      // Relationship
      try container.encode(records?.map { $0.uuid }, forKey: .records)
      try container.encode(patient?.uuid, forKey: .patient)
    }
  }

  extension Symptom: Encodable {
    enum CodingKeys: CodingKey {
      case title
      case detail
      case creationDate
      case startDate
      case uuid
      case records
      case patient
    }
  }

#endif
