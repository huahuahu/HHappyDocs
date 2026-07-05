//
//  HVersionCell.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/23.
//

import HFoundation
import SwiftUI

public struct HVersionCell: View {
  public init(overrideVersion: String? = nil) {
    self.overrideVersion = overrideVersion
  }

  private let overrideVersion: String?

  public var body: some View {
    HStack {
      Label {
        Text("version", bundle: .module)
      } icon: {
        Image(systemName: "v.circle")
      }
      Spacer()
      Text(getVersion())
    }
  }

  private func getVersion() -> String {
    if let overrideVersion {
      return overrideVersion
    }
    else {
      return HAppInfo.getAppVersion() ?? "0.0"
    }
  }
}

struct VersionCell_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      Form {
        HVersionCell(overrideVersion: "2.3")
      }
      Form {
        HVersionCell(overrideVersion: "2.3")
      }
      .environment(\.locale, .cnMainland)
    }
  }
}
