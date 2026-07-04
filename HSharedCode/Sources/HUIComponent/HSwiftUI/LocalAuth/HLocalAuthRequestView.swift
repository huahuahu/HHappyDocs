//
//  HLocalAuthRequestView.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/18.
//

#if os(iOS) || os(visionOS)
  import SwiftUI

  struct HLocalAuthRequestView: View {
    init(auth: @escaping () -> Void) {
      self.auth = auth
    }

    private let auth: () -> Void

    var body: some View {
      HLocalAuthFailView(error: nil, onRetry: auth)
    }
  }

  struct HLocalAuthRequestView_Previews: PreviewProvider {
    static var previews: some View {
      HLocalAuthRequestView {
        print("auth")
      }
    }
  }

#endif
