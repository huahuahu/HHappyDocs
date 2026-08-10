#if os(iOS)

  import SFSafeSymbols
  import SwiftUI

  extension SettingsView {
    @MainActor
    struct DiagnosticLogEntryCell: View {
      var body: some View {
        NavigationLink(value: HDiaryDestination.diagnosticLogs) {
          Label {
            Text(DiaryStringKey.Diagnostics.title)
          } icon: {
            Image(systemSymbol: .waveformPathEcg)
          }
        }
      }
    }
  }

#endif
