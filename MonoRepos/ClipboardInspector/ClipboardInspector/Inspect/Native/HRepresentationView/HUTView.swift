//
//  HUTView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/19.
//

import HLocalization
import SwiftUI
import UniformTypeIdentifiers

/// Show metadata for UTTYpe
struct HUTView: View {
  let utType: UTType

//  #if os(macOS)
  // Not working for iOS device
  // https://stackoverflow.com/questions/72628587/uttype-supertypes-not-available-when-running-on-device
  private var superTypes: [UTType] {
    utType.supertypes.sorted { $0.identifier < $1.identifier }
  }

//  #endif

  /// Row for reference url
  /// - Returns: A view to display reference url
  private func linkRow() -> some View {
    HStack {
      Text(LocalizedString.utTypeReferenceURL)
      Spacer()

      if let url = utType.referenceURL {
        Link("click me", destination: url)
      }
      else {
        Text(LocalizedString.unknown)
          .font(.body)
          .foregroundColor(.gray)
      }
    }
  }

  var body: some View {
    List {
      Section(LocalizedString.utTypeMetaInfo) {
        ForEach(utType.properties) { property in
          HStack {
            Text(property.key)
              .font(.body)
            Spacer()
            Text(property.value)
              .font(.body)
              .foregroundColor(.gray)
          }
        }

        linkRow()
      }

      Section(LocalizedString.utTypeSuperType) {
        if superTypes.isEmpty {
          Text(HLocalizedString.nothing)
        }
        else {
          ForEach(superTypes) { superType in
            NavigationLink(value: superType) {
              Text(superType.identifier)
            }
          }
        }
      }
    }
  }
}

struct HUTView_Previews: PreviewProvider {
  static var previews: some View {
    HUTView(utType: .jpeg)
  }
}
