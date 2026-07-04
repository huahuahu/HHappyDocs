//
//  ShortcutProvider.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/7/9.
//

import AppIntents
import Foundation

struct LibraryAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ClearClipboardIntents(),
      phrases: ["清空剪切板"],
      shortTitle: "intent.Clear clipboard",
      systemImageName: "gear"
    )
  }
}
