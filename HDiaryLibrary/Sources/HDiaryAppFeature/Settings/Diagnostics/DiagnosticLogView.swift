#if os(iOS)

  import HDiaryConstants
  import SFSafeSymbols
  import SwiftUI

  @MainActor
  struct DiagnosticLogView: View {
    @State private var model = DiagnosticLogViewModel()

    var body: some View {
      @Bindable var model = model

      Form {
        Section {
          Toggle(isOn: $model.isEnabled) {
            Text(DiaryStringKey.Diagnostics.enable)
          }
            .onChange(of: model.isEnabled) { _, isEnabled in
              Task {
                await model.updateDiagnosticLogging(enabled: isEnabled)
              }
            }

          if let startedAt = DiagnosticLogging.startedAt {
            LabeledContent {
              Text(startedAt, format: .dateTime)
            } label: {
              Text(DiaryStringKey.Diagnostics.sessionStarted)
            }
          }
        } footer: {
          Text(DiaryStringKey.Diagnostics.enableFooter)
        }

        Section {
          Button {
            Task {
              await model.refresh()
            }
          } label: {
            Label {
              Text(DiaryStringKey.Diagnostics.refresh)
            } icon: {
              Image(systemSymbol: .arrowClockwise)
            }
          }
          .disabled(model.isLoading)

          if let report = model.report {
            ShareLink(
              item: DiagnosticLogExport(text: report.text),
              preview: SharePreview(Text(DiaryStringKey.Diagnostics.sharePreviewTitle))
            ) {
              Label {
                Text(DiaryStringKey.Diagnostics.export)
              } icon: {
                Image(systemSymbol: .squareAndArrowUp)
              }
            }

            LabeledContent {
              Text(report.entries.count.formatted())
            } label: {
              Text(DiaryStringKey.Diagnostics.collectedEntries)
            }
          }
        }

        if model.isLoading {
          Section {
            ProgressView {
              Text(DiaryStringKey.Diagnostics.loading)
            }
          }
        }

        if let errorMessage = model.errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(.red)
              .textSelection(.enabled)
          } header: {
            Text(DiaryStringKey.Diagnostics.collectionFailed)
          }
        }

        if let report = model.report, report.entries.isEmpty == false {
          Section {
            ForEach(Array(report.entries.suffix(100).reversed())) { entry in
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(entry.level.rawValue.uppercased())
                    .font(.caption.weight(.semibold))
                  Text(entry.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  Spacer()
                  Text(entry.date, format: .dateTime.hour().minute().second())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                Text(entry.message)
                  .font(.caption.monospaced())
                  .textSelection(.enabled)
              }
            }
          } header: {
            Text(DiaryStringKey.Diagnostics.collectedLogs)
          } footer: {
            Text(DiaryStringKey.Diagnostics.previewFooter)
          }
        }
        else if model.isLoading == false, model.errorMessage == nil {
          Section {
            ContentUnavailableView {
              Label {
                Text(DiaryStringKey.Diagnostics.emptyTitle)
              } icon: {
                Image(systemSymbol: .docTextMagnifyingglass)
              }
            } description: {
              Text(DiaryStringKey.Diagnostics.emptyDescription)
            }
          }
        }

        Section {
          Text(DiaryStringKey.Diagnostics.widgetDescription)
        } header: {
          Text(DiaryStringKey.Diagnostics.widgetTitle)
        }
      }
      .navigationTitle(Text(DiaryStringKey.Diagnostics.title))
      .task {
        await model.refresh()
      }
    }
  }

#endif
