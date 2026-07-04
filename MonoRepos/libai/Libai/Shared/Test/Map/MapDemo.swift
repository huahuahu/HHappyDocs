//
//  MapDemo.swift
//  Libai
//
//  Created by huahuahu on 2021/12/28.
//

import MapKit
import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-a-map-view
struct MapDemo: View {
  @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

  var body: some View {
    Map(bounds: MapCameraBounds(centerCoordinateBounds: region))
      .environment(\.locale, .init(identifier: "zh_Hans"))
      .frame(width: 400, height: 300)
  }
}

struct MapDemo_Previews: PreviewProvider {
  static var previews: some View {
    MapDemo()
  }
}
