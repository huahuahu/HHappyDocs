//
//  IndexItem.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/10.
//

import Foundation

struct IndexItem: Identifiable {
  var id = UUID()

  let displayText: String

  let onTap: () -> Void
}
