#if os(iOS)

  import SwiftUI

  @MainActor
  struct CloudSyncDiagnosticsScreen: View {
    @State private var model = CloudSyncDiagnosticsModel.shared

    var body: some View {
      List {
        if model.loadErrorDescription != nil {
          Label {
            Text(DiaryStringKey.Data.CloudData.Diagnostics.loadFailed)
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
          }
          .foregroundStyle(.red)
        }

        if model.records.isEmpty, model.loadErrorDescription == nil {
          CloudSyncDiagnosticsEmptyView()
        }
        else {
          ForEach(model.records.sorted { $0.startDate > $1.startDate }) { record in
            CloudSyncEventRow(record: record)
          }
        }
      }
      .navigationTitle(Text(DiaryStringKey.Data.CloudData.Diagnostics.title))
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await model.load()
      }
      .toolbar {
        if let exportURL = model.exportURL {
          ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: exportURL) {
              Label {
                Text(DiaryStringKey.Data.CloudData.Diagnostics.share)
              } icon: {
                Image(systemName: "square.and.arrow.up")
              }
            }
          }
        }
      }
    }
  }

#endif
