//
//  CollectLogView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/22.
//

import HDiaryConstants
import OSLog
import SwiftUI

@MainActor
struct CollectLogView: View {
  var body: some View {
    Button(action: {
      collectLog()
    }, label: {
      Text(DebugEntry.collectLog.title)
    })
  }

  private func collectLog() {
    Log.common.info("collection log")
    do {
      let store = try OSLogStore(scope: .currentProcessIdentifier)
      let predicate = NSPredicate(format: "process == 'HDiary'")

      let logs = try store.getEntries(matching: predicate)
      for item in logs {
        guard let log = item as? OSLogEntryLog else {
          continue
        }
        print("[\(log.subsystem)]: \(log.level) \(log.composedMessage)")
      }
    }
    catch {
      Log.common.error("collection log error: \(error)")
    }
  }
}

#Preview {
  CollectLogView()
}
