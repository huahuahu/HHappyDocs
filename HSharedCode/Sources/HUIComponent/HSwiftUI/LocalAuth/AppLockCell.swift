//
//  AppLockCell.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/16.
//
#if os(iOS) || os(visionOS)
  import HLocalization
  import SwiftUI

  public struct AppLockCell: View {
    public init(appLockEnabled: Binding<Bool>) {
      self._appLockEnabled = appLockEnabled
    }

    @State private var showingAlert = false
    @Binding private var appLockEnabled: Bool

    private var failAlert: Alert {
      Alert(
        title: Text(LocalizedString.localAuthEnableFailureAlertTitle),
        message: Text(LocalizedString.localAuthEnableFailureAlertMessage),
        dismissButton: .default(Text(HLocalizedString.ok))
      )
    }

    private func onSwitchChange(to newValue: Bool) {
      if newValue {
        let canAuth = HLocalAuth.canAuthWith(policy: .deviceOwnerAuthentication)
        switch canAuth {
        case .success:
          return
        case .failure:
          appLockEnabled = false
          showingAlert = true
        }
      }
    }

    public var body: some View {
      Toggle(isOn: $appLockEnabled) {
        Label(LocalizedString.localAuthCellText, systemImage: "lock")
      }
      .tint(Color.accentColor)
      .alert(isPresented: $showingAlert) {
        failAlert
      }
      .onChange(of: appLockEnabled) { _, newValue in
        onSwitchChange(to: newValue)
      }
    }
  }

  struct AppLockCell_Previews: PreviewProvider {
    static var previews: some View {
      Form {
        AppLockCell(appLockEnabled: .constant(true))
        AppLockCell(appLockEnabled: .constant(false))
      }
    }
  }
#endif
