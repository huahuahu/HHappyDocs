//
//  HMapUtil.swift
//
//
//  Created by tigerguo on 2024/9/1.
//

import Foundation
import MapKit
import UIKit

public enum HMapUtil {
  static func mapRect(for mapItems: [MKMapItem]) -> MKMapRect {
    guard let firstItem = mapItems.first else {
      return MKMapRect.null
    }

    var rect = MKMapRect(origin: MKMapPoint(firstItem.placemark.coordinate), size: MKMapSize(width: 0, height: 0))

    for item in mapItems.dropFirst() {
      let point = MKMapPoint(item.placemark.coordinate)
      let pointRect = MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0))
      rect = rect.union(pointRect)
    }

    return rect
  }

  static func expandMapRect(_ rect: MKMapRect, byLatitudeDelta latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) -> MKMapRect {
    // Convert latitude and longitude deltas to MKMapPoints
    let topLeftCoordinate = rect.origin.coordinate

    // Calculate the deltas as map points
    let topDelta = MKMapPoint(CLLocationCoordinate2D(latitude: topLeftCoordinate.latitude + latitudeDelta, longitude: topLeftCoordinate.longitude))
    let leftDelta = MKMapPoint(CLLocationCoordinate2D(latitude: topLeftCoordinate.latitude, longitude: topLeftCoordinate.longitude + longitudeDelta))

    // Calculate the distance in map points
    let latitudeDeltaPoints = abs(topDelta.y - rect.origin.y)
    let longitudeDeltaPoints = abs(leftDelta.x - rect.origin.x)

    // Expand the rect by the calculated points
    let expandedRect = MKMapRect(
      x: rect.origin.x - longitudeDeltaPoints,
      y: rect.origin.y - latitudeDeltaPoints,
      width: rect.size.width + 2 * longitudeDeltaPoints,
      height: rect.size.height + 2 * latitudeDeltaPoints
    )

    return expandedRect
  }
}

// import MapKit

//
//// Example usage:
//
// let initialRect = MKMapRect(x: 1000, y: 1000, width: 500, height: 500)
//
//// Expand by 0.01 degrees latitude and 0.02 degrees longitude
// let expandedRect = expandMapRect(initialRect, byLatitudeDelta: 0.01, longitudeDelta: 0.02)
//
// expandedRect will be larger by the specified latitude and longitude.
