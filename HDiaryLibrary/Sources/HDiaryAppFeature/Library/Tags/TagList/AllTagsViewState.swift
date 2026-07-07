#if os(iOS)

//
//  AllTagsViewState.swift
//  HDiary
//
//  Created by Copilot on 2026/7/5.
//

struct AllTagsViewState {
  let totalTagCount: Int

  var shouldShowTotalTagCount: Bool {
    totalTagCount > 0
  }
}

#endif
