//
//  PasteBoardClearView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/7/8.
//

#if os(iOS) || os(visionOS)
  import HLocalization
  import SwiftUI

  struct PasteBoardClearView: View {
    init(noPermissionInfo: HPasteboardNoPermissionInfo) {
      self.info = noPermissionInfo
    }

    @State private var info: HPasteboardNoPermissionInfo
    var body: some View {
      List {
        clearButton
        infoView
      }
    }

    @ViewBuilder
    var clearButton: some View {
      Button {
        HPasteboard.shared.clearContent()
        info = HPasteboard.shared.getNoPermissionInfo()
      } label: {
        HStack {
          Text(LocalizedString.clearPasteboardAction)
            .bold()
        }
      }
    }

    @ViewBuilder
    var infoView: some View {
      Section(LocalizedString.currentInfoInClearPasteboardView) {
        NativePasteboardNoPermissionInfoView(noPermissionInfo: info)
      }
    }
  }

  struct PasteBoardClearView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        PasteBoardClearView(noPermissionInfo: HPasteboardNoPermissionInfo.image)

        PasteBoardClearView(noPermissionInfo: HPasteboardNoPermissionInfo.empty)
      }
    }
  }

#endif
