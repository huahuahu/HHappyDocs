//
//  SummaryDemoView.swift
//  Learn
//
//  Created by tigerguo on 2024/11/20.
//

import SwiftUI

extension AIDemo {
  @MainActor struct SummaryDemoView: View {
    @State private var isFilePickerPresented = false
    @State private var selectedFileURL: URL?
    @State private var previewURL: URL?
    @State private var isSummarySheetPresented = false
    @State private var summaryText: String?
    @State private var isSummarizing = false

    var body: some View {
      ScrollView {
        VStack {
          if let url = selectedFileURL {
            Text("Selected File: \(url)")
              .padding()

            Button("Preview") {
              self.previewURL = selectedFileURL
            }
            .quickLookPreview($previewURL)
            .padding()

            Button("Summary") {
              Task {
                await summarizeFileContent(from: url)
              }
            }
            .disabled(isSummarizing)
            .padding()
          }
          else {
            Text("No file selected")
              .padding()
          }
        }
      }
      .navigationTitle(AIDemoEntry.summary.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {
            isFilePickerPresented = true
          }) {
            Text("Pick File")
          }
        }
      }
      .sheet(isPresented: $isFilePickerPresented) {
        FilePickerView(selectedFileURL: $selectedFileURL)
      }
      .sheet(isPresented: $isSummarySheetPresented) {
        NavigationStack {
          Group {
            if let summaryText {
              ScrollView {
                Text(summaryText)
              }
              .padding()
            }
            else {
              Text("No summary available")
                .padding()
            }
          }
          .navigationTitle("Summary Result")
          .navigationBarTitleDisplayMode(.inline)
        }
      }
    }

    private func summarizeFileContent(from url: URL) async {
      isSummarizing = true
      do {
        let content = try String(contentsOf: url, encoding: .utf8)
        let summary = try await AzureAIModel.summarizeText(content)
        summaryText = summary
        isSummarySheetPresented = true
        Log.common.info("Summary result: \(summary)")
      }
      catch {
        Log.common.error("Failed to summarize content: \(error)")
        summaryText = "Failed to summarize content"
        isSummarySheetPresented = true
      }
      isSummarizing = false
    }
  }
}

#Preview {
  AIDemo.SummaryDemoView()
}
