//
//  WebInspectorView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/2.
//

import HUIComponent
import SwiftUI

struct WebInspectorView: View {
  let url: URL

  var body: some View {
    HWebView(url: url)
  }
}

struct WebInspectView_Previews: PreviewProvider {
  static var previews: some View {
    WebInspectorView(url: WebInspectorUtil.htmlFileUrl)
  }
}
