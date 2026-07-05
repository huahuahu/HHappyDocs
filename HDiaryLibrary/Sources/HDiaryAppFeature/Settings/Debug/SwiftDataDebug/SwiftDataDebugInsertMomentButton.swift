//
//  SwiftDataDebugInsertMomentButton.swift
//  HDiary
//
//  Created by tigerguo on 2025/5/5.
//

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

extension SwiftDataDebugView {
  @MainActor struct InsertMomentButton: View {
    @Binding var message: String?
    @State private var isShowingSheet = false
    @State private var insertConfig = InsertConfig()

    let sampleDataHandler: SampleDataHandler

    var body: some View {
      Button {
        isShowingSheet = true
      } label: {
        Text(verbatim: "Insert Moment")
      }
      .sheet(isPresented: $isShowingSheet) {
        NavigationView {
          InsertConfigView(config: $insertConfig) {
            insertMoments(config: insertConfig)
            isShowingSheet = false
          }
        }
      }
    }

    private func insertMoments(config: InsertConfig) {
      guard config.startDate <= config.endDate else {
        message = "Start date must be before end date"
        return
      }

      message = "Inserting \(config.count) moment(s)..."
//            DispatchQueue.global(qos: .default).async {
      Task.detached {
        do {
          try await sampleDataHandler.insertMoments(
            count: config.count,
            dateRange: config.startDate ... config.endDate
          )
          await MainActor.run {
            message = nil
            message = "Successfully inserted \(config.count) moment(s)"
          }
        }
        catch {
          Log.data.error("Failed to insert sample data: \(error)")
          await MainActor.run {
            message = nil
            message = "Failed to insert moments"
          }
        }
//                }
      }
    }
  }

  private struct InsertConfig {
    var count: Int = 1
    var startDate = Date().addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago
    var endDate = Date()
  }

  private struct InsertConfigView: View {
    @Binding var config: InsertConfig
    @Environment(\.dismiss) private var dismiss
    let onInsert: () -> Void
    @State private var numberText = ""

    var body: some View {
      Form {
        Section {
          TextField(text: $numberText) {
            Text(verbatim: "Number of moments")
          }
          .keyboardType(.numberPad)
        } header: {
          Text(verbatim: "Insert Count")
        }

        Section(content: {
          DatePicker(selection: $config.startDate, displayedComponents: [.date, .hourAndMinute]) {
            Text(verbatim: "Start Date")
          }
          DatePicker(selection: $config.endDate, in: config.startDate..., displayedComponents: [.date, .hourAndMinute]) {
            Text(verbatim: "End Date")
          }

        }, header: {
          Text(verbatim: "Date Range")
        })
      }
      .onAppear {
        numberText = "\(config.count)"
      }
      .navigationTitle(Text(verbatim: "Insert Moment Config"))
      .navigationBarItems(
        leading:
        Button {
          dismiss()
        } label: {
          Text(verbatim: "Cancel")
        },

        trailing: Button {
          config.count = Int(numberText) ?? 1
          onInsert()
        } label: {
          Text(verbatim: "Insert")
        }
      )
    }
  }
}
