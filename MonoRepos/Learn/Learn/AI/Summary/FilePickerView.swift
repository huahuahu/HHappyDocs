//
//  FilePickerView.swift
//  Learn
//
//  Created by tigerguo on 2024/11/20.
//

import SwiftUI
import UIKit

extension AIDemo {
  struct FilePickerView: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?

    func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
//        let picker = UIDocumentPickerViewController(forExporting: [])
      picker.delegate = context.coordinator
      return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
      // No update needed
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
      var parent: FilePickerView

      init(_ parent: FilePickerView) {
        self.parent = parent
      }

      func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        parent.selectedFileURL = urls.first
//        if let firstUrl = urls.first {
//          readTextFile(url: firstUrl)
//        }
      }

      func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        parent.selectedFileURL = nil
      }

      func readTextFile(url: URL) {
        do {
          // Read the contents of the file as a string
          if url.startAccessingSecurityScopedResource() {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            Log.common.info("File content: \(fileContent)")
          }

          do {
            url.stopAccessingSecurityScopedResource()
          }

          // You can use fileContent here, e.g., display it in a TextView or process it further
        }
        catch {
          Log.common.info("Failed to read the file content: \(error)")
        }
      }
    }
  }
}
