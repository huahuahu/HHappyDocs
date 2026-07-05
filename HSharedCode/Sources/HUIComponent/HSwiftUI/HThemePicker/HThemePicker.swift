//
//  HThemePicker.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/2.
//

import SwiftUI

public struct HThemePicker: View {
  public init(theme: Binding<HTheme>) {
    self._theme = theme
  }

  @Binding var theme: HTheme
  public var body: some View {
    Picker(selection: $theme, label: Label(LocalizedString.appearance, systemImage: "moon.stars")) {
      ForEach(HTheme.allCases, id: \.self) { theme in
        Text(theme.settingText)
      }
    }
    #if os(iOS) || os(watchOS)
    .sensoryFeedback(.selection, trigger: theme)
    #endif
  }
}

struct HThemePicker_Previews: PreviewProvider {
  @State static var theme: HTheme = .dark
  static var previews: some View {
    NavigationStack {
      Form {
        HThemePicker(theme: $theme)
          .navigationTitle(Text(verbatim: "list"))
      }
    }
  }
}
