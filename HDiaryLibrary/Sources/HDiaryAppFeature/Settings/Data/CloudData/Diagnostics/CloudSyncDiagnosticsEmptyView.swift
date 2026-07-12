#if os(iOS)

  import SwiftUI

  struct CloudSyncDiagnosticsEmptyView: View {
    var body: some View {
      ContentUnavailableView {
        Label {
          Text(DiaryStringKey.Data.CloudData.Diagnostics.emptyTitle)
        } icon: {
          Image(systemName: "waveform.path.ecg")
        }
      } description: {
        Text(DiaryStringKey.Data.CloudData.Diagnostics.emptyMessage)
      }
    }
  }

#endif
