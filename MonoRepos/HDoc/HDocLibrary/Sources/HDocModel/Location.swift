//
//  Location.swift
//
//
//  Created by tigerguo on 2024/9/1.
//

#if os(iOS)
  import Foundation
  import SwiftData

  @Model
  public class Location {
    public var name: String = ""
    public var address: String = ""
    /// 纬度
    public var latitude: Double?

    /// 精度
    public var longitude: Double?
    public private(set) var creationDate: Date = Date.now
    public private(set) var uuid = UUID()
    public var medicalSite: MedicalSite?

    public init(name: String, address: String, latitude: Double, longitude: Double) {
      self.name = name
      self.address = address
      self.latitude = latitude
      self.longitude = longitude
      self.creationDate = creationDate
      self.uuid = UUID()
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
      try container.encode(address, forKey: .address)
      try container.encode(latitude, forKey: .latitude)
      try container.encode(longitude, forKey: .longitude)

      try container.encode(creationDate, forKey: .creationDate)
      try container.encode(uuid, forKey: .uuid)

      // relationship
      try container.encode(medicalSite?.uuid, forKey: .medicalSite)
    }
  }

  extension Location: Encodable {
    enum CodingKeys: CodingKey {
      case name
      case address
      case creationDate
      case latitude
      case longitude
      case uuid
      case medicalSite
    }
  }

  @Model
  public class ParkingLocation {
    public var name: String = ""
    public var address: String = ""
    /// 纬度
    public var latitude: Double?

    /// 精度
    public var longitude: Double?
    public private(set) var creationDate: Date = Date.now
    public private(set) var uuid = UUID()
    public var medicalSite: MedicalSite?

    public init(name: String, address: String, latitude: Double, longitude: Double) {
      self.name = name
      self.address = address
      self.latitude = latitude
      self.longitude = longitude
      self.creationDate = creationDate
      self.uuid = UUID()
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
      try container.encode(address, forKey: .address)
      try container.encode(latitude, forKey: .latitude)
      try container.encode(longitude, forKey: .longitude)

      try container.encode(creationDate, forKey: .creationDate)
      try container.encode(uuid, forKey: .uuid)

      // relationship
      try container.encode(medicalSite?.uuid, forKey: .medicalSite)
    }
  }

  extension ParkingLocation: Encodable {
    enum CodingKeys: CodingKey {
      case name
      case address
      case creationDate
      case latitude
      case longitude
      case uuid
      case medicalSite
    }
  }

#endif
