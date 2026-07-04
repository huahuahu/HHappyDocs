//
//  HDocLocationManager.swift
//
//
//  Created by tigerguo on 2024/8/16.
//

import CoreLocation
import Foundation
import HDocAppConstants
import SwiftUI

@Observable @MainActor
public final class HDocLocationManager: NSObject, CLLocationManagerDelegate {
  @ObservationIgnored let manager = CLLocationManager()

  override public init() {
    authorizationStatus = manager.authorizationStatus
    super.init()
    manager.delegate = self
    updateIsAuthorized()

    if isAuthorized {
      manager.requestLocation()
    }
    else {
      manager.requestWhenInUseAuthorization()
    }
  }

  public enum State: Equatable {
    public static func == (lhs: HDocLocationManager.State, rhs: HDocLocationManager.State) -> Bool {
      switch (lhs, rhs) {
      case (.initial, .initial):
        return true
      case let (.success(location: l1), .success(location: l2)):
        return l1.coordinate.latitude == l2.coordinate.latitude && l1.coordinate.longitude == l2.coordinate.longitude
      case let (.fail(error: e1), .fail(error: e2)):
        return "\(e1)" == "\(e2)"
      default:
        return false
      }
    }

    case initial
    case success(location: CLLocation)
    case fail(error: Error)
  }

  public private(set) var userLocationState: State = .initial
  public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
  public private(set) var isAuthorized: Bool = false

  func requestLocation() {
    Log.map.info("requestLocation")
    userLocationState = .initial
    manager.requestLocation()
  }

  func logLocationAuthorizationStatus() {
    Log.map.info("location authorization status is \(self.manager.authorizationStatus.logString)")
  }

  public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    MainActor.assumeIsolated {
      Log.map.error("fail with error \(error)")
      userLocationState = .fail(error: error)
    }
  }

  public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    MainActor.assumeIsolated {
      if let location = locations.last {
        Log.map.info("didUpdateLocations, get last location")
        userLocationState = .success(location: location)
      }
      else {
        Log.map.error("didUpdateLocations, failed to get last location")
        userLocationState = .fail(error: HDocLocationError.noLocation)
      }
    }
  }

  public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      authorizationStatus = manager.authorizationStatus
      updateIsAuthorized()
      Log.map.info("authorizationStatus changed to \(self.authorizationStatus.logString)")
    }
  }

  private func updateIsAuthorized() {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      isAuthorized = true
    case .notDetermined:
      isAuthorized = false

    case .denied:
      isAuthorized = false

    default:
      isAuthorized = true
    }
  }
}

extension CLAuthorizationStatus {
  var logString: String {
    switch self {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorizedAlways:
      return "authorizedAlways"

    case .authorizedWhenInUse:
      return "authorizedWhenInUse"
    case .authorized:
      return "authorized"

    @unknown default:
      return "@unknown"
    }
  }
}

enum HDocLocationError: Error {
  case noLocation
}
