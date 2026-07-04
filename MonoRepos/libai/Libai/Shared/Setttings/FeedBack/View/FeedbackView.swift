//
//  FeedbackView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import AlertToast
import SwiftUI

struct FeedbackView: View {
  enum Field: Hashable {
    case feeback
  }

  enum FeedBackState {
    case inputting
    case fail
    case success
    case sending
  }

  @State private var feedBackContent = ""
  @State private var feedbackState = FeedBackState.inputting

  @FocusState private var focusedField: Field?

  func toast() -> AlertToast {
    switch feedbackState {
    case .inputting:
      return AlertToast(displayMode: .alert, type: .regular)
    case .sending:
      return AlertToast(type: .loading, title: "正在发送", subTitle: nil)
    case .success:
      return AlertToast(type: .complete(.green), title: "反馈成功")
    case .fail:
      return AlertToast(type: .systemImage("exclamationmark.triangle.fill", .red), title: "反馈失败")
    }
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack {
          TextEditor(text: $feedBackContent)
            .cornerRadius(5)
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .cornerRadius(5)
            .background(Color.secondaryBackground)
            .frame(minHeight: geometry.size.height)
            .focused($focusedField, equals: .feeback)
            .disabled(feedbackState != .inputting)
        }
      }
    }
    .toast(isPresenting: Binding(get: {
      feedbackState != .inputting
    }, set: { _ in
      hLog("ispresenting change")
      feedbackState = .inputting
    }), duration: 2, tapToDismiss: true, alert: {
      toast()
    })

    .toolbar(content: {
      ToolbarItem(placement: .navigationBarTrailing) {
        AsyncButton {
          feedbackState = .sending
          do {
            try await FeedbackSender().sendFeedback(feedBackContent)
            hLog("send feedback success")
            feedbackState = .success
          }
          catch {
            hLog("send feedback fail")
            feedbackState = .fail
          }
          Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            feedbackState = .inputting
          }
        } label: {
          Text(PredefinedString.sendFeedback)
        }.disabled(feedBackContent.isEmpty)
      }
    })

    .navigationTitle(PredefinedString.feedback)
    .onAppear {
      Task {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        focusedField = .feeback
      }
    }
    .onDisappear {
      focusedField = nil
    }
  }
}

struct FeedbackView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      FeedbackView()
    }
  }
}
