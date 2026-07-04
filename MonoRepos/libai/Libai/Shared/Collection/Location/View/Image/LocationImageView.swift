////
////  LocationImageView.swift
////  Libai (iOS)
////
////  Created by huahuahu on 2022/4/16.
////
//
// import SwiftUI
//
// struct LocationImageView: View {
//  @StateObject private var store = LocationImageStore()
//  @State private var currentPage = 0
//  #if os(iOS)
//
//    let locationID: String
//
//    var pages: [ImagePageView] {
//      var array = store.state.items?.compactMap { item -> (UIImage, String)? in
//        if let image = UIImage(data: item.image) {
//          return (image, item.id)
//        } else {
//          return nil
//        }
//      }
//      .map {
//        ImagePageView(contentType: .image($0.0, id: $0.1))
//      } ?? []
//      array.append(ImagePageView(contentType: .add(locationID)))
//      return array
//    }
//
//    @ViewBuilder
//    var content: some View {
//      TabView(content: {
//        ForEach(pages, content: { page in
//          page
//        })
//      })
//      .tabViewStyle(.page)
//      .indexViewStyle(.page(backgroundDisplayMode: .always))
//    }
//
//    var body: some View {
//      content
//        .task {
//          store.updateLocationID(locationID)
//        }
//    }
//
//  #elseif os(macOS)
//    var body: some View {
//      Text("Location Image View Mac")
//    }
//  #endif
// }
//
// struct LocationImageView_Previews: PreviewProvider {
//  static var previews: some View {
//    LocationImageView(locationID: "test")
//      .frame(height: 300)
//  }
// }
