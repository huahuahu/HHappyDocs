//
//  NativePasteboardNoPermissionInfoView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/7/9.
//

import SwiftUI
import UniformTypeIdentifiers

struct NativePasetboarCheckInfoView: View {
  init(info: HPasteboardNoPermissionInfo) {
    self.info = info
  }

  private let info: HPasteboardNoPermissionInfo

  var body: some View {
    List {
      Section {
        NativePasteboardNoPermissionInfoView(noPermissionInfo: info)
      }

      Section {
        NavigationLink(value: InspectEntry.checkNativeContent) {
          Text(InspectEntry.checkNativeContent.text)
        }
      }
    }
  }
}

struct NativePasteboardNoPermissionInfoView: View {
  init(noPermissionInfo: HPasteboardNoPermissionInfo) {
    self.info = noPermissionInfo
  }

  private let info: HPasteboardNoPermissionInfo

  var body: some View {
    ItemsView(types: info.types)
    BoolInfoView(boolInfo: info.stringInfo)
    BoolInfoView(boolInfo: info.urlInfo)
    BoolInfoView(boolInfo: info.colorInfo)
    BoolInfoView(boolInfo: info.imageInfo)
  }
}

struct BoolInfoView: View {
  let boolInfo: PasteboardBoolInfo

  var body: some View {
    DisclosureGroup {
      Text(boolInfo.info)
        .font(.callout)
        .foregroundStyle(.secondary)
    } label: {
      HStack {
        Text(boolInfo.label)
        Spacer()
        Text(boolInfo.value.localizedDescription)
          .bold()
      }
    }
  }
}

struct ItemsView: View {
  init(types: [[String]]) {
    self.types = types
  }

  private let types: [[String]]

  @State private var topExpanded: Bool = true

  var body: some View {
    DisclosureGroup(LocalizedString.item, isExpanded: $topExpanded) {
      ForEach(types.indices, id: \.self) { index in
        itemView(for: index)
      }
    }
  }

  @ViewBuilder
  private func itemView(for index: Int) -> some View {
    DisclosureGroup(LocalizedString.item(for: (index + 1))) {
      ForEach(types[index].indices, id: \.self) { innerIndex in
        typeView(for: types[index][innerIndex])
      }
    }
  }

  @ViewBuilder
  func typeView(for typeString: String) -> some View {
    if let utType = UTType(typeString) {
      NavigationLink(value: utType) {
        Text(typeString)
      }
    }
    else {
      Text(typeString)
    }
  }
}

struct NativePasetboarCheckInfoView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      NativePasetboarCheckInfoView(info: .image)
    }
  }
}
