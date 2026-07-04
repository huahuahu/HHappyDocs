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
  public class MedicalStaff {
    public var name: String = ""
    public var detail: String = ""
    public private(set) var creationDate: Date = Date.now
    public private(set) var uuid = UUID()
    public var records: [Record]? = []
    public var sites: [MedicalSite]? = []

    public init(name: String, detail: String = "") {
      self.name = name
      self.detail = detail
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
      try container.encode(records?.map { $0.uuid }, forKey: .records)
    }
  }

  extension MedicalStaff: Encodable {
    enum CodingKeys: CodingKey {
      case name
      case detail
      case creationDate
      case records
      case uuid
    }
  }

#endif
