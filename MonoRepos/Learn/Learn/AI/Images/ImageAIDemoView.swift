//
//  ImageAIDemoView.swift
//  Learn
//
//  Created by tigerguo on 2024/11/25.
//

import PhotosUI
import SwiftUI

extension AIDemo {
  @MainActor struct ImageAIDemoView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var resultText: String?
    @State private var isProcessing = false
    @State private var isImageViewerPresented = false
    @State private var isResultViewerPresented = false

    var body: some View {
      VStack {
        if let image = selectedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 300)
            .padding()
            .onTapGesture {
              isImageViewerPresented = true
            }
        }
        else {
          Text("No image selected")
            .padding()
        }

        PhotosPicker(
          selection: $selectedItem,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Text("Pick Image")
        }
        .onChange(of: selectedItem) { _, newItem in
          Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
              selectedImage = uiImage
            }
          }
        }
        .padding()

        Button("Process Image") {
          Task {
            await processImage()
          }
        }
        .disabled(isProcessing || selectedImage == nil)
        .padding()

        if let resultText = resultText {
          Text("Result: \(resultText)")
            .padding()
        }
      }
      .navigationTitle("Image AI Demo")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $isImageViewerPresented) {
        if let image = selectedImage {
          ImageViewer(image: image)
        }
      }
      .sheet(isPresented: $isResultViewerPresented) {
        if let resultText = resultText {
          ResultViewer(resultText: resultText)
        }
      }
    }

    private func processImage() async {
      guard let image = selectedImage else { return }
      isProcessing = true
      defer { isProcessing = false }

      // Replace with actual image processing logic
      do {
        resultText = try await AzureAIModel.describeImage(image)
        Log.common.info("Image processed: \(resultText ?? "nil")")
        isResultViewerPresented = true
      }
      catch {
        Log.common.error("Failed to process image: \(error)")
        resultText = "Failed to process image"
        isResultViewerPresented = true
      }
    }
  }
}

struct ImageViewer: View {
  let image: UIImage
  @Environment(\.dismiss) var dismiss
  @State private var scale: CGFloat = 1.0

  var body: some View {
    NavigationStack {
      ScrollView([.horizontal, .vertical], showsIndicators: false) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .scaleEffect(scale)
          .gesture(
            MagnificationGesture()
              .onChanged { value in
                scale = value
              }
              .onEnded { value in
                scale = value
              }
          )
      }
      .background(Color.black)
      .ignoresSafeArea()
      .navigationTitle("Image Viewer")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Dismiss") {
            dismiss()
          }
        }
      }
    }
  }
}

private struct ResultViewer: View {
  let resultText: String
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        Text(resultText)
          .padding()
      }
      .navigationTitle("Result")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Dismiss") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  AIDemo.ImageAIDemoView()
}
