//
//  SettingsView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/17.
//

import HLocalization
import HUIComponent
import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var settings: Settings

  var body: some View {
    Form {
      #if DEBUG
//          Button {
//            let pasteboard = NSPasteboard.general
//            pasteboard.clearContents() // clear previous contents
//
//            let image = NSImage(named: "testpng")!
//            let item = NSPasteboardItem()
//            let imageData = image.toJpegData()!
//            item.setData(imageData, forType: .png)
//            pasteboard.writeObjects([item])
//
//          } label: {
//            Text("set image")
//          }
//
      #endif
      #if !os(visionOS)
        Section {
          AppLockCell(appLockEnabled: $settings.pAppLockEnabled)
          HThemePicker(theme: $settings.pTheme)
        }
      #endif

      Section {
        HFeedBackCell(model: HFeedbackModel(appName: LocalizedString.appName))
        HVersionCell()
      }
    }
    .onAppear(perform: onAppearFunc)
    .navigationTitle(HLocalizedString.setting)
  }

  private func onAppearFunc() {
//    print("can deviceOwnerAuthenticationWithBiometrics:  \(HLocalAuth.canAuthWith(policy: .deviceOwnerAuthenticationWithBiometrics))")
//
//        print("can deviceOwnerAuthentication:  \(HLocalAuth.canAuthWith(policy: .deviceOwnerAuthentication))")
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      SettingsView()
        .environmentObject(Settings.shared)
        .environment(\.locale, .en)

      SettingsView()
        .environmentObject(Settings.shared)
        .environment(\.locale, .cnMainland)
    }
  }
}
