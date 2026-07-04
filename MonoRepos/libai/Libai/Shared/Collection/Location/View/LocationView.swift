//
//  LocationView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import HLocation
import MapKit
import SwiftUI

struct LocationView: View {
  let location: Location
  @State private var showMapSelector = false
  var body: some View {
    GeometryReader { _ in

      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            VStack(alignment: .leading, spacing: 10) {
              Text("古代名字：\(location.displayName)")
                .padding(.horizontal)
              Text("现代名字：\(location.currentName)")
                .padding(.horizontal)
            }
            Spacer()
          }
          mapView
          HStack {
            Spacer()
            openMapButton
            Spacer()
          }
        }
      }
    }
    .confirmationDialog(
      PredefinedString.mapSelection,
      isPresented: $showMapSelector,
      actions: {
        mapSelectionView
      }
    )
    .navigationTitle(location.displayName)
  }

  @ViewBuilder
  private var mapView: some View {
    Map(bounds: MapCameraBounds(centerCoordinateBounds: MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
      span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    ))) {
      Marker(coordinate: location.coordinate) {
        EmptyView()
      }
      .tint(Color.accentColor)
    }
    .frame(height: 300)
  }

  @ViewBuilder
  private var openMapButton: some View {
    Button {
      showMapSelector = true
    } label: {
      Text(PredefinedString.openInMap)
        .padding()
        .foregroundColor(.primaryLabel)
    }
    .background(Color.secondaryBackground)
    .cornerRadius(10)
  }

  @ViewBuilder
  private var mapSelectionView: some View {
    Button {
      AMapOpener(sourceAppName: PredefinedString.apppNameForLocation)
        .open(HLocation(location: location))
    } label: {
      Text(PredefinedString.gaodeMap)
        .foregroundColor(.accentColor)
    }

    Button {
      BaiduMapOpener(sourceAppName: PredefinedString.apppNameForLocation)
        .open(HLocation(location: location))
    } label: {
      Text(PredefinedString.baiduMap)
    }
  }
}

#if DEBUG
  struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        NavigationView {
          LocationView(location: .碎叶城)
        }
        NavigationView {
          LocationView(location: .碎叶城)
        }
        .environment(\.colorScheme, .dark)
      }
    }
  }

#endif

private extension HLocation {
  init(location: Location) {
    self.init(
      name: location.currentName,
      content: "古 \(location.displayName)",
      latitude: location.latitude,
      longitude: location.longitude
    )
  }
}
