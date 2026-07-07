//
//  StorageUsageView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/25.
//

#if os(iOS)

import SwiftUI

@MainActor
struct StorageUsageView: View {
  var body: some View {
    Form {
      LocalCacheView()
      CloudStorageSection()
    }
    .navigationTitle(Text(DiaryStringKey.Data.StorageUsage.storageUsage))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview { @MainActor in
  NavigationStack {
    StorageUsageView()
  }
}

#endif
