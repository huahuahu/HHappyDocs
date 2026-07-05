//
//  HFeedBackCell.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/22.
//

import SwiftUI

public struct HFeedBackCell: View {
  public init(model: HFeedbackModel) {
    self.model = model
  }

  let model: HFeedbackModel

  @State private var showAlert = false

  public var body: some View {
    Button {
      onTap()
    } label: {
      Label(LocalizedString.feedbackCellText, systemImage: "exclamationmark.bubble")
    }
    .alert(
      LocalizedString.feedbackErrorTitle,
      isPresented: $showAlert,
      presenting: (),
      actions: {}
    ) {
      _ in
      Text(LocalizedString.feedbackErrorMessage)
    }
  }

  private func onTap() {
    Task {
      let openSuccess = await model.openFeedbackURL()
      await MainActor.run {
        showAlert = !openSuccess
      }
    }
  }
}

struct HFeedBackCell_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      Form {
        HFeedBackCell(model: .demo)
      }
    }
  }
}
