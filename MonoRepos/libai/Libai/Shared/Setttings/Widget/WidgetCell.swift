//
//  WidgetCell.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/8.
//

import SwiftUI

struct WidgetCell: View {
  var body: some View {
    NavigationLink {
      WidgetConfigView()
    } label: {
      Text(PredefinedString.widget)
    }
  }
}

struct WidgetCell_Previews: PreviewProvider {
  static var previews: some View {
    WidgetCell()
  }
}
