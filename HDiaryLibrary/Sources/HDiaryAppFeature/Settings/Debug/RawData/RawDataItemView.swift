//
//  RawDataItemView.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/3.
//

import HDiaryConstants
import HDiaryModel
import HMedia
import HUIComponent
import SwiftData
import SwiftUI

@MainActor
struct RawDataItemView<T: RawData>: View {
  let item: T
  var body: some View {
    if let mediaItem = item as? MediaItem {
      infoView(for: mediaItem)
    }
    else if let happyImage = item as? HappyImage {
      infoView(for: happyImage)
    }
    else {
      commonView
    }
  }

  @ViewBuilder
  private var commonView: some View {
    ScrollView {
      Text(item.getDetailString())
        .textSelection(.enabled)
    }
    .padding()
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private func infoView(for mediaItem: MediaItem) -> some View {
    if let itemAndThumbail = MediaItemAndThumbnail(mediaItem: mediaItem) {
      ScrollView {
        VStack(
          alignment: .leading,
          spacing: 8,
          content: {
            VStack(content: {
              LabeledContent {
                Text(mediaItem.pathExtension)
              } label: {
                Text(verbatim: "extension")
              }
              LabeledContent {
                imageSizeInfoView(for: mediaItem.data)
              } label: {
                Text(verbatim: "dimension")
              }
              DebugMediaStorageView(
                dataCount: mediaItem.data.count,
                thumbnail1000Count: mediaItem.thumbnailData1000px?.count,
                thumbnail500Count: mediaItem.thumbnailData500px?.count,
                thumbneil150Count: mediaItem.thumbnailData150px?.count,
                totalSize: mediaItem.totalSize
              )
            })
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            HMediaItemView(itemAndThumbail: itemAndThumbail)
          }
        )
        .padding()
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    else {
      DebugMediaStorageView(
        dataCount: mediaItem.data.count,
        thumbnail1000Count: mediaItem.thumbnailData1000px?.count,
        thumbnail500Count: mediaItem.thumbnailData500px?.count,
        thumbneil150Count: mediaItem.thumbnailData150px?.count,
        totalSize: mediaItem.totalSize
      )
    }
  }

  @ViewBuilder
  private func infoView(for happyImage: HappyImage) -> some View {
    if let itemAndThumbail = MediaItemAndThumbnail(happyImage: happyImage) {
      ScrollView {
        VStack(
          alignment: .leading,
          spacing: 8,
          content: {
            VStack(content: {
              LabeledContent {
                Text(verbatim: "heic")
              } label: {
                Text(verbatim: "extension")
              }
              LabeledContent {
                imageSizeInfoView(for: happyImage.data)
              } label: {
                Text(verbatim: "dimension")
              }
              DebugMediaStorageView(
                dataCount: happyImage.data.count,
                thumbnail1000Count: happyImage.thumbnailData1000px?.count,
                thumbnail500Count: happyImage.thumbnailData500px?.count,
                thumbneil150Count: happyImage.thumbnailData150px?.count,
                totalSize: nil
              )
            })
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            HMediaItemView(itemAndThumbail: itemAndThumbail)
          }
        )
        .padding()
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    else {
      DebugMediaStorageView(
        dataCount: happyImage.data.count,
        thumbnail1000Count: happyImage.thumbnailData1000px?.count,
        thumbnail500Count: happyImage.thumbnailData500px?.count,
        thumbneil150Count: happyImage.thumbnailData150px?.count,
        totalSize: nil
      )
    }
  }

  @ViewBuilder
  private func fileSizeView(for storageCountInBytes: Int) -> some View {
    Text(storageCountInBytes.formatted(.byteCount(style: .file)))
  }

  @ViewBuilder
  private func imageSizeInfoView(for imageData: Data) -> some View {
    if let imageSize = try? UIImage.imageSize(for: imageData) {
      Text(imageSize.debugDescription)
    }
    else {
      EmptyView()
    }
  }
}

@MainActor
private struct DebugMediaStorageView: View {
  @State private var isExpanded = true

  private let dataCount: Int
  private let thumbnail1000Count: Int?
  private let thumbnail500Count: Int?
  private let thumbneil150Count: Int?
  private let totalSize: Int

  init(dataCount: Int, thumbnail1000Count: Int?, thumbnail500Count: Int?, thumbneil150Count: Int?, totalSize: Int? = nil) {
    self.dataCount = dataCount
    self.thumbnail1000Count = thumbnail1000Count
    self.thumbnail500Count = thumbnail500Count
    self.thumbneil150Count = thumbneil150Count
    if let totalSize {
      self.totalSize = totalSize
    }
    else {
      self.totalSize = dataCount + (thumbnail1000Count ?? 0) + (thumbnail500Count ?? 0) + (thumbneil150Count ?? 0)
    }
  }

  var body: some View {
    DisclosureGroup(
      isExpanded: $isExpanded,
      content: {
        LabeledContent {
          Text(dataCount.formatted(.byteCount(style: .file)))
        } label: {
          Text(verbatim: "raw data size")
        }
        .foregroundStyle(.secondary)
        .padding(.leading)
        if let thumbnail1000 = thumbnail1000Count {
          LabeledContent {
            Text(thumbnail1000.formatted(.byteCount(style: .file)))
          } label: {
            Text(verbatim: "thumbnail 1000 size")
          }
          .foregroundStyle(.secondary)
          .padding(.leading)
        }
        if let thumbnail500 = thumbnail500Count {
          LabeledContent {
            Text(thumbnail500.formatted(.byteCount(style: .file)))
          } label: {
            Text(verbatim: "thumbnail 500 size")
          }
          .foregroundStyle(.secondary)
          .padding(.leading)
        }

        if let thumbnail150 = thumbneil150Count {
          LabeledContent {
            Text(thumbnail150.formatted(.byteCount(style: .file)))
          } label: {
            Text(verbatim: "thumbnail 150 size")
          }
          .foregroundStyle(.secondary)
          .padding(.leading)
        }

      },
      label: {
        LabeledContent {
          Text(totalSize.formatted(.byteCount(style: .file)))
        } label: {
          Text(verbatim: "storage size")
        }
      }
    )
  }
}

private extension RawData {
  func getDetailString() -> String {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      let formatter = DateFormatter()
      formatter.dateStyle = .full
      formatter.timeStyle = .full

      encoder.dateEncodingStrategy = .formatted(formatter)
      let data = try encoder.encode(self)
      return String(data: data, encoding: .utf8) ?? ""
    }
    catch {
      Log.data.error("failed to encode \(type(of: self)) \(error)")
      return ""
    }
  }
}

@MainActor
private struct PreviewContainerView: View {
  @Query private var items: [MediaItem]
  var body: some View {
    NavigationStack {
      if let item = items.first {
        RawDataItemView(item: item)
      }
      else {
        Text(verbatim: "No item")
      }
    }
  }
}

#Preview { @MainActor in
  PreviewContainerView()
    .previewEnvironment()
}
