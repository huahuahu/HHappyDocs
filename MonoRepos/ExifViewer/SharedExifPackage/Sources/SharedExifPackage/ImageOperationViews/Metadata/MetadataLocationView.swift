//
//  LocationView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/16.
//
import MapKit
import SwiftUI

@MainActor
struct MetadataLocationView: View {
  let location: CLLocationCoordinate2D?

  @ScaledMetric private var cornerRadius: CGFloat = 10.0
  @ScaledMetric private var height: CGFloat = 200.0

  @State private var showFullScreenMap = false

  var body: some View {
    if let location = location {
      Map(initialPosition: .region(MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))) {
        Marker(coordinate: location) {
          EmptyView()
        }
      }
      .cornerRadius(cornerRadius)
      .frame(height: height)
      .onTapGesture {
        showFullScreenMap.toggle()
      }
      .fullScreenCover(isPresented: $showFullScreenMap) {
        fullScreenMap(for: location)
      }
    }
    else {
      LabeledContent {
        Text(verbatim: "-")
      } label: {
        Text(ExifString.MetaData.location.hDocLocalized())
      }
    }
  }

  @ViewBuilder
  private func fullScreenMap(for location: CLLocationCoordinate2D) -> some View {
    NavigationStack {
      Map(initialPosition: .region(MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))) {
        Marker(coordinate: location) {
          EmptyView()
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showFullScreenMap = false
          } label: {
            Text(ExifString.Common.close.hDocLocalized())
          }
        }
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    VStack {
      MetadataLocationView(location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    VStack {
      MetadataLocationView(location: nil)
    }
  }
}
