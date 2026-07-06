//
//  HDiaryWidgetBundle.swift
//  HDiaryWidget
//
//  Created by tigerguo on 2023/7/14.
//

import SwiftUI
import WidgetKit

public struct HDiaryWidgetFeatureBundle: WidgetBundle {
  public init() {}

  public var body: some Widget {
    MomentWidget()
//        HDiaryWidgetLiveActivity()
  }
}
