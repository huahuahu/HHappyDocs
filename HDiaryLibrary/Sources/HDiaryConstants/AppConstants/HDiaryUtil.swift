//
//  HDiaryUtil.swift
//  HDiaryLibrary
//
//  Created by tigerguo on 2024/12/23.
//

import Foundation
#if canImport(UIKit)
  import UIKit
#endif

public enum HDiaryUtil {
  // Why I am doing this?
  // https://developer.apple.com/forums/thread/746843?answerId=784514022#784514022
  @MainActor public static var isJournalingSuggestionsAvailable: Bool {
    #if canImport(JournalingSuggestions)
      #if canImport(UIKit)
        if #available(iOS 17.2, *) {
          return UIDevice.current.userInterfaceIdiom == .phone
        }
        return false
      #else
        return false
      #endif
    #else
      return false
    #endif
  }
}
