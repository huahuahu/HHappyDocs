//
//  SwiftDataDebugMessageStatusView.swift
//  HDiary
//
//  Created by tigerguo on 2025/5/5.
//

import SwiftUI

extension SwiftDataDebugView {
  @MainActor struct StatusView: View {
    @Binding var message: String?

    var body: some View {
      if let message {
        messageView(for: message)
      }
      else {
        EmptyView()
      }
    }

    @ViewBuilder
    private func messageView(for message: String) -> some View {
      Color.clear
        .background(.ultraThinMaterial)
        .overlay {
          VStack {
            Text(message)
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(8)
              .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

            Button {
              self.message = nil

            } label: {
              Text(verbatim: "Clear")
            }
          }
        }
    }
  }
}
