//
//  AsyncButton.swift
//  Libai
//
//  Created by huahuahu on 2022/2/3.
//

import SwiftUI

extension AsyncButton {
  enum ActionOption: CaseIterable {
    case disableButton
    case showProgressView
  }
}

struct AsyncButton<Label: View>: View {
  var action: () async -> Void
  var actionOptions = Set(ActionOption.allCases)

  @ViewBuilder var label: () -> Label

  @State private var isDisabled = false
  @State private var showProgressView = false

  var body: some View {
    Button(
      action: {
        if actionOptions.contains(.disableButton) {
          isDisabled = true
        }

        if actionOptions.contains(.showProgressView) {
          showProgressView = true
        }

        Task {
          var progressViewTask: Task<Void, Error>?

          if actionOptions.contains(.showProgressView) {
            progressViewTask = Task {
              try await Task.sleep(nanoseconds: 150_000_000)
              showProgressView = true
            }
          }

          await action()
          progressViewTask?.cancel()

          isDisabled = false
          showProgressView = false
        }
      },
      label: {
        ZStack {
          // We hide the label by setting its opacity
          // to zero, since we don't want the button's
          // size to change while its task is performed:
          label().opacity(showProgressView ? 0 : 1)

          if showProgressView {
            ProgressView()
          }
        }
      }
    )
    .disabled(isDisabled)
  }
}

extension AsyncButton where Label == Text {
  init(_ label: String,
       actionOptions _: Set<ActionOption> = Set(ActionOption.allCases),
       action: @escaping () async -> Void) {
    self.init(action: action) {
      Text(label)
    }
  }
}

extension AsyncButton where Label == Image {
  init(systemImageName: String,
       actionOptions _: Set<ActionOption> = Set(ActionOption.allCases),
       action: @escaping () async -> Void) {
    self.init(action: action) {
      Image(systemName: systemImageName)
    }
  }
}

struct AsyncButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      AsyncButton(
        action: {
          try? await Task.sleep(nanoseconds: 2_000_000_000)
          print("clicked")
        },
        actionOptions: [.disableButton],
        label: {
          Image(systemName: "hand.thumbsup.fill")
        }
      )
      .padding(10)

      AsyncButton(
        systemImageName: "hand.thumbsup.fill",
        action: {
          try? await Task.sleep(nanoseconds: 2_000_000_000)
          print("clicked")
        }
      )
    }
  }
}
