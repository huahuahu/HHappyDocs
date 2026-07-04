//
//  HEmptyView.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/3/19.
//

import SwiftUI

/// Show empty status
public struct HEmptyView: View {
  public init() {}

  public var body: some View {
    Text(LocalizedString.empty)
  }
}

struct HEmptyView_Previews: PreviewProvider {
  static var previews: some View {
    HEmptyView()
      .environment(\.locale, .init(identifier: "zh-cn"))
  }
}
