//
//  NoMomentView.swift
//  HDiary
//
//  Created by tigerguo on 2023/9/3.
//

#if os(iOS)

  import SwiftUI

  public struct NoMomentView: View {
    public init() {}

    public var body: some View {
      let statement = String(localized: "moment.empty.label", bundle: .module)
      ContentUnavailableView {
        Label(
          title: { Text(statement) },
          icon: { Image(systemName: "list.bullet") }
        )
      }
    }
  }

  #Preview {
    NoMomentView()
  }

#endif
