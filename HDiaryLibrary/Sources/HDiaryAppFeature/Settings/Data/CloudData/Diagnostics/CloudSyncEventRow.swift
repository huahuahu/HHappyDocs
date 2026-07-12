#if os(iOS)

  import SwiftUI

  struct CloudSyncEventRow: View {
    let record: CloudSyncEventRecord

    private var presentation: CloudSyncEventPresentation {
      CloudSyncEventPresentation(record: record)
    }

    private var kindText: String {
      switch presentation.kind {
      case .setup:
        "setup"
      case .importData:
        "import"
      case .export:
        "export"
      }
    }

    private var statusText: LocalizedStringResource {
      switch presentation.state {
      case .inProgress:
        DiaryStringKey.Data.CloudData.Diagnostics.inProgress
      case .succeeded:
        DiaryStringKey.Data.CloudData.Diagnostics.succeeded
      case .failed:
        DiaryStringKey.Data.CloudData.Diagnostics.failed
      }
    }

    private var statusSymbol: String {
      switch presentation.state {
      case .inProgress:
        "arrow.triangle.2.circlepath"
      case .succeeded:
        "checkmark.circle.fill"
      case .failed:
        "xmark.octagon.fill"
      }
    }

    private var statusStyle: Color {
      switch presentation.state {
      case .inProgress:
        .secondary
      case .succeeded:
        .green
      case .failed:
        .red
      }
    }

    var body: some View {
      VStack(alignment: .leading) {
        HStack(alignment: .firstTextBaseline) {
          Text(verbatim: kindText)
            .font(.headline)

          Spacer()

          Label {
            Text(statusText)
          } icon: {
            Image(systemName: statusSymbol)
          }
          .font(.subheadline)
          .foregroundStyle(statusStyle)
        }

        if presentation.state == .inProgress {
          LabeledContent {
            Text(
              presentation.startDate,
              format: .dateTime.year().month().day().hour().minute().second()
            )
          } label: {
            Text(DiaryStringKey.Data.CloudData.Diagnostics.started)
          }
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
        else {
          if let endDate = presentation.endDate {
            LabeledContent {
              Text(
                endDate,
                format: .dateTime.year().month().day().hour().minute().second()
              )
            } label: {
              Text(DiaryStringKey.Data.CloudData.Diagnostics.ended)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
          }

          if let duration = presentation.duration {
            LabeledContent {
              Text(
                Duration.seconds(duration),
                format: .time(pattern: .hourMinuteSecond)
              )
            } label: {
              Text(DiaryStringKey.Data.CloudData.Diagnostics.duration)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
          }
        }

        if presentation.state == .failed, let error = record.error {
          if let errorCodeText = presentation.errorCodeText {
            Text(verbatim: errorCodeText)
              .font(.caption)
          }

          Text(verbatim: error.message)
            .font(.caption)

          if let retryDate = presentation.retryDate {
            VStack(alignment: .leading) {
              Text(DiaryStringKey.Data.CloudData.Diagnostics.retryAt)
              Text(
                retryDate,
                format: .dateTime.year().month().day().hour().minute().second()
              )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        }
      }
    }
  }

#endif
