//
//  LocalAuthModifier.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/16.
//
#if os(iOS) || os(visionOS)
  import Foundation
  import LocalAuthentication
  import SwiftUI

  private enum HAuthStatus {
    case notStarted
    case success
    case failure(error: Error)
  }

  public struct LocalAuthConfig {
    public init(touchIDReason: String, appName: String) {
      self.touchIDReason = touchIDReason
      self.appName = appName
    }

    /// Localized string used to request touch id permission
    let touchIDReason: String

    let appName: String
  }

  final class HLocalAuthConfigStore: ObservableObject {
    @Published var config: LocalAuthConfig

    init(config: LocalAuthConfig) {
      self.config = config
    }
  }

  public struct LocalAuthModify: ViewModifier {
    private enum AuthError: Error {
      case unknown
    }

    init(needAuth: Binding<Bool>) {
      self._needAuth = needAuth
    }

    @EnvironmentObject private var localAuthConfigStore: HLocalAuthConfigStore

    @State private var authStatus: HAuthStatus = .notStarted

    /// Is first time on view hierarchy
    @State private var isInit = true

    @Binding var needAuth: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var blurRadius: CGFloat = 0

    @ViewBuilder
    public func body(content: Content) -> some View {
      // Use overlay to perserve view identity
      content.overlay {
        aboveView()
      }
      .blur(radius: blurRadius)
      .onAppear {
        if isInit, needAuth {
          auth()
        }
        isInit = false
      }
      .onChange(of: needPerformAuth) { _, newValue in
        authStatus = .notStarted
        if newValue {
          auth()
        }
      }
      .onChange(of: scenePhase, { _, newValue in
        onSceneChange(to: newValue)
      })
    }

    private var needPerformAuth: Bool {
      needAuth && scenePhase != .background
    }

    @ViewBuilder
    private func aboveView() -> some View {
      if needAuth {
        switch authStatus {
        case .notStarted:
          authView
        case .success:
          EmptyView()
        case .failure(let error):
          authFailureView(with: error)
        }
      }
      else {
        EmptyView()
      }
    }

    private var authView: some View {
      HLocalAuthRequestView(auth: {
        auth()
      })
    }

    private func authFailureView(with error: Error) -> some View {
      HLocalAuthFailView(error: error) {
        auth()
      }
    }

    private func auth() {
      let context = LAContext()
      var error: NSError?

      if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
        Task {
          do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localAuthConfigStore.config.touchIDReason)
            await MainActor.run {
              authStatus = success ? .success : .failure(error: AuthError.unknown)
            }
          }
          catch {
            await MainActor.run {
              authStatus = .failure(error: error)
            }
          }
        }
      }
      else {
        if let error {
          authStatus = .failure(error: error as Error)
        }
        else {
          authStatus = .failure(error: AuthError.unknown)
        }
      }
    }

    private func onSceneChange(to newPhase: ScenePhase) {
      switch newPhase {
      case .active:
        blurRadius = 0
      case .background, .inactive:
        if needAuth {
          blurRadius = 20
        }
        else {
          blurRadius = 0
        }

      @unknown default:
        blurRadius = 0
      }
    }
  }

  extension View {
    public func localAuth(needAuth: Binding<Bool>, localAuthConfig: LocalAuthConfig) -> some View {
      modifier(LocalAuthModify(needAuth: needAuth))
        .environmentObject(HLocalAuthConfigStore(config: localAuthConfig))
    }
  }
#endif
