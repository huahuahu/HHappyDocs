//
//  HDocAddLocationView.swift
//
//
//  Created by tigerguo on 2024/8/16.
//

import CoreLocationUI
import HDocAppConstants
import HDocModel
import MapKit
import SwiftUI

@MainActor
public struct HDocAddLocationView: View {
  @Environment(HDocLocationManager.self) var locationManager
  @Environment(\.dismiss) private var dismiss

  @Namespace private var mapScope
  @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
  @State private var visibleRegion: MKCoordinateRegion?

  @State private var placeMarks: [HPlaceMark] = []
  @State private var selectedPlaceMark: HPlaceMark?

  @Binding private var favPlaceMark: HPlaceMark?
  @State private var hasAppeared = false

  enum Constants {
    static let defaultMapLatitudeDelta = 0.15
    static let defaultMapLongitudeDelta = 0.15
    // The search result should be inset. This is the value measured by 经纬度
    static let searchResultInsetPadding = 0.01
  }

  public init(favPlaceMark: Binding<HPlaceMark?>) {
    self._favPlaceMark = favPlaceMark
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      MapReader { _ in
        Map(position: $cameraPosition, selection: $selectedPlaceMark, scope: mapScope) {
          if locationManager.isAuthorized {
            UserAnnotation()
          }
          ForEach(placeMarks) { placeMark in
            if placeMark != favPlaceMark {
              Marker(placeMark.name, coordinate: placeMark.coordinate)
                .tag(placeMark)
            }
          }
          if let favPlaceMark {
            Marker(coordinate: favPlaceMark.coordinate) {
              Label(
                title: { Text(favPlaceMark.name) },
                icon: { Image(hdocSymbol: .star) }
              )
            }
            .tag(favPlaceMark)
          }
        }
        .mapControls({
          if locationManager.isAuthorized {
            MapUserLocationButton(scope: mapScope)
          }
          MapCompass(scope: mapScope)
          MapPitchToggle(scope: mapScope)
        })
        .onAppear(perform: {
          if hasAppeared {
            return
          }
          hasAppeared = true
          showFavPlaceMarkIfNeeded()
        })
        .onMapCameraChange({ context in
          visibleRegion = context.region
        })
        .safeAreaInset(edge: .top) {
          LocationSearchTextField { searchText in
            Task { @MainActor in
              await searchLocation(with: searchText)
            }
          }
          .padding()
        }
        .sheet(
          item: $selectedPlaceMark,
          content: {
            placeMark in
            PlaceMarkView(
              placeMark: placeMark,
              actionType: placeMark == favPlaceMark ? .remove : .add
            ) { mark in
              if mark == favPlaceMark {
                favPlaceMark = nil
              }
              else {
                favPlaceMark = mark
              }
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
          }
        )
        .onChange(of: locationManager.userLocationState) { _, newValue in
          updateCameraPosition(with: newValue)
        }
      }

      if !locationManager.isAuthorized {
        LocationButton(.currentLocation) {
          locationManager.requestLocation()
        }
        .symbolVariant(.fill)
        .labelStyle(.titleAndIcon)
        .clipShape(.capsule)
        .padding(.bottom)
      }
    }
  }

  private func updateCameraPosition(with newLocationState: HDocLocationManager.State) {
    if case .success(let location) = newLocationState {
      let region = MKCoordinateRegion(
        center: location.coordinate,
        span: MKCoordinateSpan(latitudeDelta: Constants.defaultMapLatitudeDelta, longitudeDelta: Constants.defaultMapLongitudeDelta)
      )
      cameraPosition = .region(region)
    }
    else {
      cameraPosition = .userLocation(fallback: .automatic)
    }
  }

  private func searchLocation(with searchText: String) async {
    do {
      let mapItems = try await HMapSearchService.searchPlaces(for: searchText, visibleRegion: visibleRegion)
      placeMarks = mapItems.map(HPlaceMark.init)
      Log.map.info("Search with \(searchText), get \(mapItems.count) items")
      if !mapItems.isEmpty {
        let containingRect = HMapUtil.mapRect(for: mapItems)
        let targetRect = HMapUtil.expandMapRect(
          containingRect,
          byLatitudeDelta: Constants.searchResultInsetPadding,
          longitudeDelta: Constants.searchResultInsetPadding
        )
        withAnimation {
          cameraPosition = .rect(targetRect)
        }
      }
      else {}
    }
    catch {
      Log.map.error("Search with \(searchText) failed with error \(error, privacy: .public)")
    }
  }

  private func showFavPlaceMarkIfNeeded() {
    if let favPlaceMark {
      let region = MKCoordinateRegion(
        center: favPlaceMark.coordinate,
        span: MKCoordinateSpan(latitudeDelta: Constants.defaultMapLatitudeDelta, longitudeDelta: Constants.defaultMapLongitudeDelta)
      )
      cameraPosition = .region(region)
    }
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(action: {
        dismiss()
      }, label: {
        Label(
          title: { Text(verbatim: "") },
          icon: { Image(hdocSymbol: .xMark) }
        )
        .labelStyle(.iconOnly)
      })
    }
  }
}

@MainActor
private struct LocationSearchTextField: View {
  // Search
  @State private var searchText = ""
  @FocusState private var searchFieldFocus: Bool
  @ScaledMetric private var searchTextClearButtonOffset = 5.0

  let onSearchSubmit: (String) -> Void

  init(onSubmit: @escaping (String) -> Void) {
    self.onSearchSubmit = onSubmit
  }

  var body: some View {
    TextField(text: $searchText, prompt: Text(LocationString.searchPlaceHolder.hDocLocalized())) {
      Text(LocationString.location.hDocLocalized())
    }
    .textFieldStyle(.roundedBorder)
    .textContentType(.location)
    .autocorrectionDisabled()
    .textInputAutocapitalization(.never)
    .focused($searchFieldFocus)
    .submitLabel(.search)
    .onSubmit {
      onSearchSubmit(searchText)
    }
    .overlay(alignment: .trailing) {
      if searchFieldFocus {
        Button(action: {
          searchText = ""
          searchFieldFocus = false
        }, label: {
          Image(hdocSymbol: .xMark)
            .symbolVariant(.circle)
            .symbolVariant(.fill)
        })
        .offset(x: -searchTextClearButtonOffset)
      }
    }
  }
}

#Preview("Add Location") {
  NavigationStack {
    HDocAddLocationView(favPlaceMark: .init(get: {
      nil
    }, set: { _ in

    }))
  }
  .environment(HDocLocationManager())
}
