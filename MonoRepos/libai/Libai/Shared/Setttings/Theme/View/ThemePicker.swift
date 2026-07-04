//
//  ThemePicker.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

struct ThemePicker: View {
  @Binding var theme: Int
  var body: some View {
    Picker(selection: $theme, label: Text("外观")) {
      ForEach(Theme.allCases) { theme in
        Text(theme.settingText)
          .tag(theme.rawValue)
      }
    }
    .pickerStyle(.inline)
  }
}

struct ThemePicker_Previews: PreviewProvider {
  @State static var theme = 0
  static var previews: some View {
    NavigationView {
      List {
        ThemePicker(theme: $theme)
      }
      .navigationTitle("list")
    }
  }
}
