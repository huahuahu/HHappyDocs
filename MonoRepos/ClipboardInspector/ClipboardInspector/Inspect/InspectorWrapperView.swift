//
//  InspectorWrapperView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/18.
//

import SwiftUI

struct InspectorWrapperView: View {
  let entry: InspectEntry

  var body: some View {
    switch entry {
    #if os(iOS) || os(visionOS)
      case .checkNativeInfo:
        NativePasetboarCheckInfoView(info: HPasteboard.shared.getNoPermissionInfo())
    #endif
    case .checkNativeContent:
      NativeInspectorView(pasteboardItems: HPasteboard.shared.getItems())
    case .checkWeb:
      WebInspectorView(url: WebInspectorUtil.htmlFileUrl)
    }
  }
}

struct InspectorWrapperView_Previews: PreviewProvider {
  static var previews: some View {
    InspectorWrapperView(entry: .checkNativeContent)
  }
}
