//
//  MapSearchService.swift
//
//
//  Created by tigerguo on 2024/8/16.
//

import Foundation
import MapKit

enum HMapSearchService {
  static func searchPlaces(for searchText: String, visibleRegion: MKCoordinateRegion?) async throws -> [MKMapItem] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchText
    if let visibleRegion {
      request.region = visibleRegion
    }
    let searchItems = try await MKLocalSearch(request: request).start()
    return searchItems.mapItems
  }
}
