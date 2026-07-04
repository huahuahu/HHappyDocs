//
//  MedicalSite.swift
//
//
//  Created by tigerguo on 2024/1/12.
//

#if os(iOS)
  import Foundation
  import SwiftData

  @Model
  public class MedicalSite {
    public var name: String = ""
    public var detail: String = ""
    public private(set) var creationDate: Date = Date.now
    public private(set) var uuid = UUID()

    @Relationship(inverse: \Record.medicalSites)
    public var records: [Record]? = []

    @Relationship(inverse: \ParkingLocation.medicalSite)
    public var parkingLocation: ParkingLocation?

    @Relationship(inverse: \Location.medicalSite)
    public var location: Location?

    @Relationship(deleteRule: .nullify, inverse: \MedicalStaff.sites)
    public var staffs: [MedicalStaff]? = []

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
      try container.encode(records?.map { $0.uuid }, forKey: .records)
      try container.encode(location?.uuid, forKey: .location)
      try container.encode(parkingLocation?.uuid, forKey: .parkingLocation)
    }
  }

  extension MedicalSite: Encodable {
    enum CodingKeys: CodingKey {
      case name
      case detail
      case creationDate
      case records
      case uuid
      case location
      case parkingLocation
    }
  }

#endif
