//
//  LocationString.swift
//
//
//  Created by tigerguo on 2024/8/16.
//

#if os(iOS)

  import Foundation

  enum LocationString {
    public static let searchPlaceHolder = LocalizedStringResource("location.searchPlaceHolder", table: "Localizable", comment: "Place holder for search place")

    public static let location = LocalizedStringResource("location.location", table: "Localizable", comment: "Location")
    public static let addLocation = LocalizedStringResource("location.add", table: "Localizable", comment: "Text shown in button when adding location")
    public static let removeLocation = LocalizedStringResource("location.remove", table: "Localizable", comment: "Text shown in button when removing location")
    public static let appleMapName = LocalizedStringResource("location.appleMapName", table: "Localizable", comment: "Text shown in button when show location in Apple Map")
    public static let openInMap = LocalizedStringResource("location.openInMap", table: "Localizable", comment: "Text shown in menu which would show different ways for opening in a map")
  }

  extension LocalizedStringResource {
    func hDocLocalized() -> String {
      String(localized: .init(stringLiteral: self.key), bundle: .module)
    }
  }

#endif
