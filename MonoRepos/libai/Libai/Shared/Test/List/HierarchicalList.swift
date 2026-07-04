//
//  HierarchicalList.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import SwiftUI

struct HierarchicalList: View {
  struct FileItem: Hashable, Identifiable, CustomStringConvertible {
    var id: Self { self }
    var name: String
    var children: [Self]?
    var description: String {
      switch children {
      case nil:
        return "📄 \(name)"
      case let .some(children):
        return children.isEmpty ? "📂 \(name)" : "📁 \(name)"
      }
    }
  }

  let fileHierarchyData: [FileItem] = [
    FileItem(
      name: "users",
      children:
      [
        FileItem(
          name: "user1234",
          children:
          [
            FileItem(
              name: "Photos",
              children:
              [
                FileItem(name: "photo001.jpg"),
                FileItem(name: "photo002.jpg"),
              ]
            ),
            FileItem(
              name: "Movies",
              children:
              [FileItem(name: "movie001.mp4")]
            ),
            FileItem(name: "Documents", children: []),
          ]
        ),
        FileItem(
          name: "newuser",
          children:
          [FileItem(name: "Documents", children: [])]
        ),
      ]
    ),
    FileItem(name: "private", children: nil),
  ]
  var body: some View {
    List(fileHierarchyData, children: \.children) { item in
      Text(item.description)
    }
  }
}

struct HierarchicalList_Previews: PreviewProvider {
  static var previews: some View {
    HierarchicalList()
  }
}
