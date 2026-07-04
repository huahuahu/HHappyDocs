//
//  HPlaceMark.swift
//
//
//  Created by tigerguo on 2024/8/16.
//

import Foundation
import HDocModel
import MapKit

/// Represent a location in map
public struct HPlaceMark: Hashable, Equatable, Identifiable {
  public private(set) var name: String
  public private(set) var address: String
  /// 纬度
  public private(set) var latitude: Double

  /// 精度
  public private(set) var longitude: Double

  init(name: String, address: String, latitude: Double, longitude: Double) {
    self.name = name
    self.address = address
    self.latitude = latitude
    self.longitude = longitude
  }

  public var id: String {
    return "latitude: \(latitude), longitude: \(longitude)"
  }

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

public extension HPlaceMark {
  init(_ mkMapItem: MKMapItem) {
    self.init(
      name: mkMapItem.placemark.name ?? "",
      address: mkMapItem.placemark.title ?? "",
      latitude: mkMapItem.placemark.coordinate.latitude,
      longitude: mkMapItem.placemark.coordinate.longitude
    )
  }

  init?(_ location: Location) {
    guard let latitude = location.latitude,
          let longitude = location.longitude else {
      return nil
    }

    self.init(
      name: location.name,
      address: location.address,
      latitude: latitude,
      longitude: longitude
    )
  }

  init?(_ location: ParkingLocation) {
    guard let latitude = location.latitude,
          let longitude = location.longitude else {
      return nil
    }

    self.init(
      name: location.name,
      address: location.address,
      latitude: latitude,
      longitude: longitude
    )
  }
}

#if DEBUG
  extension HPlaceMark {
    static let 中盟 = HPlaceMark(name: "中盟", address: "虎丘区酿慧路108号", latitude: 31.24963, longitude: 120.733417)
  }
#endif
