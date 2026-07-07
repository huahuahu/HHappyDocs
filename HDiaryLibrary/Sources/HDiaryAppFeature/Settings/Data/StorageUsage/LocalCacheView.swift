//
//  LocalCacheView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/25.
//

#if os(iOS)

import HDiaryConstants
import HFoundation
import SwiftUI

extension StorageUsageView {
  @MainActor
  struct LocalCacheView: View {
    private enum LocalCacheState {
      case calculating
      case calculated(sizeInByte: UInt64)
    }

    @State private var state: LocalCacheState = .calculating
    @State private var uuid = UUID()
    var body: some View {
      Section {
        content
      } footer: {
        Text(DiaryStringKey.Data.StorageUsage.cachedStorageDescription)
      }
      .task(id: uuid) {
        Log.data.info("calculate using id \(uuid)")
        let tmpFileSize = await calculateTmpFileSize()
        withAnimation {
          state = .calculated(sizeInByte: tmpFileSize)
        }
      }
    }

    @ViewBuilder
    var content: some View {
      switch state {
      case .calculating:
        ProgressView {
          Label {
            Text(DiaryStringKey.Data.StorageUsage.calculatingLocalCacheLabel)
          } icon: {
            Image(hDiarySymbol: .hourglass)
          }
        }
      case .calculated(let sizeInByte):
        LabeledContent {
          Text(sizeInByte.formatted(.byteCount(style: .file)))
        } label: {
          Text(DiaryStringKey.Data.StorageUsage.cachedStorageLabel)
        }
        if sizeInByte > 0 {
          ClearCacheButton(directoryToClear: FileManager.default.temporaryDirectory.path(percentEncoded: false)) {
            uuid = UUID()
          }
        }
      }
    }
  }
}

extension StorageUsageView.LocalCacheView {
  nonisolated func calculateTmpFileSize() async -> UInt64 {
    Log.data.info("#\(#function) in main thread? \(Thread.isMainThread)")
    let tmpPath = FileManager.default.temporaryDirectory.path(percentEncoded: false)
    var isDirectory: ObjCBool = false

    let fileExists = FileManager.default.fileExists(atPath: tmpPath, isDirectory: &isDirectory)
    guard fileExists else { return 0 }
    guard isDirectory.boolValue else {
      Log.data.error("tmp path is a file instead of path")
      return 0
    }

    let size = HFileUtil.folderSize(atPath: tmpPath)
    return size ?? 0
  }
}

extension StorageUsageView.LocalCacheView {
  @MainActor struct ClearCacheButton: View {
    let directoryToClear: String
    let onClearFinish: () -> Void
    @State private var isCleaning = false

    var body: some View {
      Button { Task {
        isCleaning = true
        await clearCache()
        isCleaning = false
        onClearFinish()
      }
      } label: {
        Label(
          title: { Text(isCleaning ? DiaryStringKey.Common.clearing : DiaryStringKey.Common.clear) },
          icon: { Image(hDiarySymbol: .trash) }
        )
      }
      .disabled(isCleaning)
    }

    nonisolated func clearCache() async {
      let fileManager = FileManager.default
      do {
        let contents = try fileManager.contentsOfDirectory(atPath: directoryToClear)
        Log.data.info("#\(#function) in main thread? \(Thread.isMainThread)")
        for item in contents {
          let fullPath = (directoryToClear as NSString).appendingPathComponent(item)

          do {
            try fileManager.removeItem(atPath: fullPath)
            Log.data.info("Successfully removed item at path: \(fullPath, privacy: .public)")
          }
          catch {
            Log.data.error("Could not remove item at path: \(fullPath, privacy: .public). Error: \(error.localizedDescription, privacy: .public)")
          }
        }
      }
      catch {
        Log.data.error("Error reading contents of directory at path: \(directoryToClear, privacy: .public). Error: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    Form {
      StorageUsageView.LocalCacheView()
    }
  }
}

#endif
