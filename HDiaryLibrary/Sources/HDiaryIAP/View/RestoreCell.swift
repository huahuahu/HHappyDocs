//
//  RestoreCell.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation

#if os(iOS)
  import HDiaryConstants
  import StoreKit
  import SwiftUI

  @MainActor
  public struct HDiaryIAPRestoreCell: View {
    enum RestoreState {
      case idle
      case restoring
      case fail(Error)
      case success

      var isRestoring: Bool {
        if case .restoring = self {
          return true
        }
        return false
      }

      var finished: Bool {
        switch self {
        case .idle, .restoring:
          return false
        case .success, .fail:
          return true
        }
      }
    }

    public init() {}

    @State private var restoreState = RestoreState.idle

    public var body: some View {
      Button(action: {
        restoreState = .restoring
        Task.detached {
          do {
            try await AppStore.sync()
            Log.iap.info("restore purchase finished")
            await MainActor.run {
              restoreState = .success
            }
          }
          catch {
            Log.iap.error("restore purpase error: \(error)")
            await MainActor.run {
              restoreState = .fail(error)
            }
          }
        }
      }, label: {
        Label(
          title: { Text(IAPString.restore.hDocLocalized()) },
          icon: {
            Image(hDiarySymbol: .restorePurchase)
              .symbolVariant(.circle)
          }
        )
      })
      .disabled(restoreState.isRestoring)
      .alert(alertTitle, isPresented: .init(get: {
        restoreState.finished
      }, set: { presenting in
        if !presenting {
          restoreState = .idle
        }
      })) {
        Button(role: .cancel, action: {}, label: {
          Text(IAPString.cancel.hDocLocalized())
        })
      }
    }

    private var alertTitle: Text {
      switch restoreState {
      case .idle, .restoring:
        Text(verbatim: "")
      case .fail:
        Text(IAPString.restoreFail.hDocLocalized())
      case .success:
        Text(IAPString.restoreSuccess.hDocLocalized())
      }
    }
  }

  #Preview {
    NavigationStack {
      Form {
        HDiaryIAPRestoreCell()
      }
    }
  }
#endif
