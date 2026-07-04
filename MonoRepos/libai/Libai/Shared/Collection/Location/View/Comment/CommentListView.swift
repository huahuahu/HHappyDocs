////
////  CommentListView.swift
////  Libai (iOS)
////
////  Created by huahuahu on 2022/4/10.
////
//
// import Foundation
// import SwiftUI
//
// struct LocationIDForComment: Hashable {
//  let id: String
// }
//
// struct CommentListView: View {
//  let locationID: LocationIDForComment
//  @StateObject private var store = LocationCommentStore()
//  @State private var isAdding = false
//
//  var addButton: some View {
//    Button {
//      isAdding = true
//    } label: {
//      Label("", systemImage: SystemImage.add)
//        .font(.title)
//    }
//    .shadow(radius: 1)
//    .padding([.bottom, .trailing])
//  }
//
//  @ViewBuilder
//  func list() -> some View {
//    if let comments = store.state.items, !comments.isEmpty {
//      List(comments) {
//        comment in
//        Text(comment.content)
//      }
//      .listStyle(.plain)
//      .refreshable {
//        await store.refresh()
//      }
//
//    } else {
//      EmptyContentView()
//    }
//  }
//
//  var content: some View {
//    list()
//      .safeAreaInset(edge: .bottom) {
//        HStack {
//          Spacer()
//          addButton
//        }
//      }
//      .popover(
//        isPresented: $isAdding,
//        attachmentAnchor: .point(.bottom),
//        arrowEdge: .bottom
//      ) {
//        CommentEditView(locationID: locationID.id, isPresenting: $isAdding) {
//          Task {
//            try? await Task.sleep(nanoseconds: 1.inNanoSeconds)
//            await store.refresh()
//          }
//        }
//      }
//  }
//
//  var body: some View {
//    content
//      .navigationTitle(PredefinedString.comments)
//      .onAppear {
//        store.updateLocationID(locationID.id)
//      }
//  }
// }
//
// struct CommentListView_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationView {
//      CommentListView(locationID: LocationIDForComment(id: "碎叶城"))
//        .listStyle(.plain)
//    }
//  }
// }
