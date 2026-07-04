//
//  CloudDataEntryCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/9/22.
//

import HDocModel
import SwiftUI

extension CloudDataEntryScreen {
  @MainActor struct DataEntryCell<T: CloudRecord>: View {
    @ScaledMetric private var paddingBetweenText = 1.0
    let recordType: LocalizedStringResource

    @State private var model = CloudDataEntryModel<T>()

    var body: some View {
      VStack(alignment: .leading) {
        Text(recordType)
          .font(.body)
          .foregroundStyle(.primary)

        DateLabel(state: model.state)
          .padding(.top, paddingBetweenText)
      }
      .task {
        if model.state.isIdle {
          await model.refresh()
        }
      }
    }
  }
}

@MainActor
private struct DateLabel<T: CloudRecord>: View {
  let state: CloudDataEntryModel<T>.State
  var body: some View {
    switch state {
    case .idle:
      EmptyView()
    case .loading:
      HStack {
        ProgressView()
        Text(HDocString.CloudData.syncing)
          .foregroundStyle(.secondary)
          .font(.footnote)
      }

    case .error(let err):
      Text(err.localizedDescription)
        .font(.footnote)
        .foregroundStyle(.red)

    case .loaded(modifiedDate: let date):
      HStack {
        Text(HDocString.Common.lastUpdatedDate)
          .bold()
        if let date {
          Text(date.formatted(date: .numeric, time: .standard))
        }
        else {
          Text(HDocString.Common.noData)
        }
      }
      .foregroundStyle(.secondary)
      .font(.footnote)
    }
  }
}

#Preview(body: {
  NavigationStack {
    List {
      CloudDataEntryScreen.DataEntryCell<MedicalSite>(recordType: "MedicalSite")
    }
  }
})

#Preview("hadDate", body: {
  NavigationStack {
    List {
      DateLabel(state: CloudDataEntryModel<MedicalSite>.State.loaded(modifiedDate: Date.now))
    }
  }
})

#Preview("no date", body: {
  NavigationStack {
    List {
      DateLabel(state: CloudDataEntryModel<MedicalSite>.State.loaded(modifiedDate: nil))
    }
  }
})

#Preview("loading", body: {
  NavigationStack {
    List {
      VStack {
        Text(verbatim: "Cloud Data")
        DateLabel(state: CloudDataEntryModel<MedicalSite>.State.loading)
      }
    }
  }
})
