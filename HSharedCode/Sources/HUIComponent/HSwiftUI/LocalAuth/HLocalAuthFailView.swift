//
//  HLocalAuthFailView.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/18.
//
#if os(iOS) || os(visionOS)
  import SwiftUI

  struct HLocalAuthFailView: View {
    init(error: Error?, onRetry: @escaping () -> Void) {
      self.error = error
      self.onRetry = onRetry
    }

    @ScaledMetric private var cornerRadius = 10
    private let error: Error?
    @EnvironmentObject private var configStore: HLocalAuthConfigStore
    private let onRetry: () -> Void

    var body: some View {
      NavigationStack {
        VStack(alignment: .center) {
          error.map {
            Text($0.localizedDescription)
              .padding()
          }

          Text(LocalizedString.unlockToProceed)
            .font(.headline)
            .padding()
          Button(unlockString) {
            onRetry()
          }
          .foregroundColor(.white)
          .padding()
          .background(Color.accentColor)
          .cornerRadius(cornerRadius)
        }
        .embedInScrollView()
        .navigationTitle(unlockString)
        .hNavigationBarTitleDisplayMode(.inline)
      }
    }

    private var unlockString: String {
      LocalizedString.unlock(appName: configStore.config.appName)
    }
  }

  struct HLocalAuthFailView_Previews: PreviewProvider {
    enum TestError: Error {
      case test
    }

    static var previews: some View {
      Group {
        HLocalAuthFailView(error: TestError.test) {
          print("retry called")
        }
        .environmentObject(HLocalAuthConfigStore(config: LocalAuthConfig(touchIDReason: "reason", appName: "app")))
        .environment(\.dynamicTypeSize, .medium)

        HLocalAuthFailView(error: nil) {
          print("retry called")
        }
        .environmentObject(HLocalAuthConfigStore(config: LocalAuthConfig(touchIDReason: "reason", appName: "app")))
      }
    }
  }
#endif
