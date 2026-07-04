//
//  ThumbnailGenerateView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/13.
//

import AVFoundation
import HFoundation
import Observation
import QuickLook
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

private var thumbnailSize = CGSize(width: 50, height: 50)

@MainActor
struct ThumbnailGenerateView: View {
  private let fileWithThumbnails: [FileWithThumbnail] = [
    FileWithThumbnail(fileName: "file-sample_150kB", fileExtension: "pdf"),
    FileWithThumbnail(fileName: "Drawing", fileExtension: "vsdx"),
    FileWithThumbnail(fileName: "file_example_MP4_480_1_5MG", fileExtension: "mp4"),
    FileWithThumbnail(fileName: "file_example_PPT_250kB", fileExtension: "ppt"),
    FileWithThumbnail(fileName: "file_example_WEBM_640_1_4MB", fileExtension: "webm"),
    FileWithThumbnail(fileName: "sample_960x400_ocean_with_audio", fileExtension: "mpg"),
    FileWithThumbnail(fileName: "file-sample_100kB", fileExtension: "doc"),
    FileWithThumbnail(fileName: "file_example_JPG_100kB", fileExtension: "jpg"),
    FileWithThumbnail(fileName: "file_example_ODS_10", fileExtension: "ods"),
    FileWithThumbnail(fileName: "file_example_TIFF_1MB", fileExtension: "tiff"),
    FileWithThumbnail(fileName: "file_example_WEBP_50kB", fileExtension: "webp"),
    FileWithThumbnail(fileName: "sample_960x400_ocean_with_audio", fileExtension: "wmv"),
    FileWithThumbnail(fileName: "file-sample_100kB", fileExtension: "rtf"),
    FileWithThumbnail(fileName: "file_example_MP3_700KB", fileExtension: "mp3"),
    FileWithThumbnail(fileName: "file_example_OOG_1MG", fileExtension: "ogg"),
    FileWithThumbnail(fileName: "file_example_WEBM_480_900KB", fileExtension: "webm"),
    FileWithThumbnail(fileName: "sample4", fileExtension: "wma"),
  ]

  var body: some View {
    List {
      supportedImageView
      supportedVideoView
      ForEach(fileWithThumbnails) { fileWithThumbnail in
        Section(fileWithThumbnail.extensin) {
          if let thumbnail = fileWithThumbnail.thumbnail {
            Image(uiImage: thumbnail)
              .resizable()
              .scaledToFit()
              .frame(width: thumbnailSize.width, height: thumbnailSize.height, alignment: .leading)
              .border(.red, width: 1)
          }
          else {
            Text("No")
          }
        }
      }
    }
  }

  @ViewBuilder
  private var supportedImageView: some View {
    DisclosureGroup("supported image type") {
      let types = (CGImageSourceCopyTypeIdentifiers() as? [String])?.sorted() ?? []
      ForEach(0 ..< types.count, id: \.self) { index in
        Text("\(String(describing: types[index]))")
      }
    }
  }

  @ViewBuilder
  private var supportedVideoView: some View {
    DisclosureGroup("supported video type") {
      let types = AVURLAsset.audiovisualTypes().map { $0.rawValue }.sorted()
      ForEach(0 ..< types.count, id: \.self) { index in
        Text("\(String(describing: types[index]))")
      }
    }
  }
}

@Observable
class FileWithThumbnail: Identifiable {
  init(fileName: String, fileExtension: String) {
    self.fileName = fileName
    self.extensin = fileExtension
    let url = Bundle.main.url(forResource: fileName, withExtension: extensin)!
    request = QLThumbnailGenerator.Request(
      fileAt: url,
      size: thumbnailSize,
      scale: UIScreen.main.scale,
      representationTypes: .all
    )

//    generateBest()
    saveUrl()
  }

  let request: QLThumbnailGenerator.Request
  let fileName: String
  let extensin: String
  let id: UUID = UUID()

  var thumbnail: UIImage?

  //            https://developer.apple.com/documentation/quicklookthumbnailing/creating_quick_look_thumbnails_to_preview_files_in_your_app
  // Approach #1, use generateBestRepresentation
  private func generateBest() {
    Task {
      do {
        let thumbnailRepresentation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
        await MainActor.run {
          thumbnail = thumbnailRepresentation.uiImage
        }
      }
      catch {
        Log.common.error("get thumbnail fail for \(self.fileName).\(self.extensin)")
      }
    }
  }

//   Approach #2, use generateRepresentations(for:update:)
//  private func generateAndUpdate() {
//      Task {
//          await     QLThumbnailGenerator.shared.generateRepresentations(for: request) { representation, representionType, error in
//              guard let representation = representation else {
//                Log.common.error("fialed to get thumbnail fail for \(fileName).\(extensin) for type \(representionType.rawValue) error: \(String(describing: error))")
//                return
//              }
//
//              await MainActor.run {
//                Log.common.info("get thumbnail fail for \(fileName).\(extensin) with type \(representionType)")
//                thumbnail = representation.uiImage
//              }
//            }
//
//      }
//  }

  // Approach #3, save to url

  private func saveUrl() {
    Task {
      let url = URL.makeTempUrl().appendingPathExtension("jpg")
      do {
        try await QLThumbnailGenerator.shared.saveBestRepresentation(for: request, to: url, as: UTType.jpeg)
        let data = try Data(contentsOf: url)
        await MainActor.run {
          Log.common.info("get thumbnail for \(self.fileName).\(self.extensin) url \(url)")
          thumbnail = UIImage(data: data)
        }
      }
      catch {
        Log.common.error("fialed to get thumbnail fail for \(self.fileName).\(self.extensin)  error: \(String(describing: error))")
      }
    }
  }
}

#Preview {
  ThumbnailGenerateView()
}
