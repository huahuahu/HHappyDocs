//
//  ClearClipboardIntents.swift
//  ClipboardIntents
//
//  Created by tigerguo on 2023/7/9.
//

import AppIntents

struct ClearClipboardIntents: AppIntent {
  static var title: LocalizedStringResource = "intent.Clear clipboard"

  static var description = IntentDescription("intent.clearClipboard.summary")

  @MainActor
  func perform() async throws -> some IntentResult {
    HPasteboard.shared.clearContent()
    return .result()
  }

  static var openAppWhenRun: Bool = true
}
