//
//  ImageHeaderView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/8.
//
#if os(iOS)
  import QuickLook
  import SwiftUI
  import UIKit

  @MainActor
  struct ImageHeaderView: View {
    let image: UIImage
    let imageUrl: URL
    let onRemove: () -> Void
    @State private var previewingUrl: URL?

    var body: some View {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .containerRelativeFrame(.vertical, alignment: .top, { length, axis in
          switch axis {
          case .vertical:
            return length * 0.3
          default:
            return length
          }
        })
        .clipped()
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1) // 边框颜色和宽度
        )
        .contentShape(.rect)
        .onTapGesture {
          previewingUrl = imageUrl
        }
        .quickLookPreview($previewingUrl)
        .overlay(alignment: .topTrailing) {
          deleteButton
        }
    }

    private var deleteButton: some View {
      Button {
        onRemove()
      } label: {
        Label {
          Text(ExifString.PhotoDisplay.deletePhotoDisplay.hDocLocalized())
        } icon: {
          Image(hExifSymbol: .remove)
            .font(.subheadline)
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
        }
        .labelStyle(.iconOnly)
      }
      .padding(8)
    }
  }

  #if DEBUG
    #Preview { @MainActor in
      let size = CGSize(width: 500, height: 900)
      let renderer = UIGraphicsImageRenderer(size: size)
      let image = renderer.image { context in
        UIColor.red.setFill()
        context.fill(CGRect(origin: .zero, size: size))
      }
      let url = URL(string: "https://www.google.com")!
      //      guard let url = URL(string: "https://www.google.com") else {
      //          fatalError("Invalid URL")
      //      }
      NavigationStack {
        ScrollView {
          ImageHeaderView(image: image, imageUrl: url) {
            print("Remove tapped")
          }
        }
        .padding(.horizontal, 10)
      }
    }
  #endif

#endif
