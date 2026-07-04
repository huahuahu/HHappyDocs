//
//  Patient.swift
//
//
//  Created by tigerguo on 2024/5/8.
//

#if os(iOS)
  import Foundation
  import SwiftData

  @Model
  public class Patient {
    public var name: String = ""
    public var detail: String = ""
    public private(set) var creationDate: Date = Date.now
    public private(set) var uuid = UUID()
    @Relationship(deleteRule: .cascade) public var symptoms: [Symptom]? = []

    public init(name: String) {
      self.name = name
      self.creationDate = .now
      self.uuid = UUID()
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
      try container.encode(detail, forKey: .detail)
      try container.encode(creationDate, forKey: .creationDate)
      try container.encode(uuid, forKey: .uuid)

      // relationship
      try container.encode(symptoms?.map { $0.uuid }, forKey: .symptoms)
    }
  }

  extension Patient: Encodable {
    enum CodingKeys: CodingKey {
      case name
      case detail
      case creationDate
      case symptoms
      case uuid
    }
  }

#endif
