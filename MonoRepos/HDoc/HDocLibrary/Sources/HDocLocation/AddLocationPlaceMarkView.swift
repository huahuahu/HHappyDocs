//
//  AddLocationPlaceMarkView.swift
//
//
//  Created by tigerguo on 2024/9/1.
//

import Foundation
import HDocAppConstants
import HLocation
import MapKit
import SwiftUI

extension HDocAddLocationView {
  @MainActor
  struct PlaceMarkView: View {
    let placeMark: HPlaceMark
    let actionBlock: (HPlaceMark) -> Void
    let actionType: ActionType

    enum ActionType {
      case add
      case remove

      var buttonRole: ButtonRole? {
        switch self {
        case .add:
          return nil
        case .remove:
          return .destructive
        }
      }
    }

    @Environment(\.dismiss) private var dismiss

    init(placeMark: HPlaceMark, actionType: ActionType, actionBlock: @escaping (HPlaceMark) -> Void) {
      self.placeMark = placeMark
      self.actionType = actionType
      self.actionBlock = actionBlock
    }

    var body: some View {
      NavigationStack {
        ScrollView {
          HStack(alignment: .firstTextBaseline) {
            titleInfoView
            Spacer()
            openButton
          }
          addRemoveButton
        }
      }
    }

    private var titleInfoView: some View {
      VStack(alignment: .leading) {
        Text(placeMark.name)
          .multilineTextAlignment(.leading)
          .lineLimit(nil)
          .font(.title)
          .bold()
          .padding(.bottom)

        Text(placeMark.address)
          .multilineTextAlignment(.leading)
          .lineLimit(nil)
          .font(.body)
      }
      .padding()
    }

    private var openButton: some View {
      Menu {
        Button(action: {
          Log.map.info("Open place \(placeMark.id) in gaode map")
          AMapOpener(sourceAppName: AppConstants.appNameForOpenLocation)
            .open(HLocation(placeMark: placeMark))
        }) {
          Text(HLocationString.gaodeMap)
        }

        Button(action: {
          Log.map.info("Open place \(placeMark.id) in baidu map")
          BaiduMapOpener(sourceAppName: AppConstants.appNameForOpenLocation)
            .open(HLocation(placeMark: placeMark))
        }) {
          Text(HLocationString.baiduMap)
        }

        Button(action: {
          openInMap()
        }) {
          Text(LocationString.appleMapName.hDocLocalized())
        }

      } label: {
        Label(
          title: { Text(LocationString.openInMap.hDocLocalized()) },
          icon: { Image(hdocSymbol: .map).imageScale(.medium) }
        )
        .labelStyle(.iconOnly)
      }
      .buttonStyle(.borderedProminent)
      .padding(.trailing)
    }

    @ViewBuilder
    private var addRemoveButton: some View {
      Button(role: actionType.buttonRole, action: {
        dismiss()
        actionBlock(placeMark)
      }, label: {
        switch actionType {
        case .add:
          Label(
            title: {
              Text(LocationString.addLocation.hDocLocalized())
            },
            icon: {
              Image(hdocSymbol: .plus)
                .symbolVariant(.circle)
                .symbolVariant(.fill)
            }
          )

        case .remove:
          Label(
            title: {
              Text(LocationString.removeLocation.hDocLocalized())
            },
            icon: {
              Image(hdocSymbol: .trash)
                .symbolVariant(.circle)
                .symbolVariant(.fill)
            }
          )
        }
      })
      .buttonStyle(.borderedProminent)
    }

    private func openInMap() {
      Log.map.info("Open place \(placeMark.id) in map")
      // Define a location using coordinates
      let coordinate = CLLocationCoordinate2D(latitude: placeMark.latitude, longitude: placeMark.longitude)
      let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
      mapItem.name = placeMark.name

//          let launchOptions = [
//              MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
//          ]

      mapItem.openInMaps(launchOptions: [:])
    }
  }
}

private extension HLocation {
  init(placeMark: HPlaceMark) {
    self.init(
      name: placeMark.name,
      content: nil,
      latitude: placeMark.latitude,
      longitude: placeMark.longitude
    )
  }
}

#if DEBUG
  #Preview("PlaceMarkView", body: {
    Text(verbatim: "test")
      .sheet(isPresented: .constant(true), content: {
        HDocAddLocationView.PlaceMarkView(placeMark: .中盟, actionType: .add) { _ in
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])

      })
  })

#endif
