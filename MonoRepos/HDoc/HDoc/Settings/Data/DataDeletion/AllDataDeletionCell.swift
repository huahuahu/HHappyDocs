//
//  AllDataDeletionCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/2/2.
//

import HDocAppConstants
import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct AllDataDeletionCell: View {
  @Environment(\.modelContext) private var modelContext

  @State private var showDeleteAlert = false
  @State private var deleteResult: Result<Void, Error>?

  var body: some View {
    Button(role: .destructive, action: {
      Log.data.info("Delete all data button tapped")
      showDeleteAlert = true
    }, label: {
      Label(
        title: { Text(HDocString.Deletion.deleteAllDataLabel) },
        icon: { Image(hdocSymbol: .trash).foregroundStyle(.red) }
      )
    })
    .alert(Text(HDocString.Deletion.deleteAllDataLabel), isPresented: $showDeleteAlert) {
      Button(role: .destructive) {
        Log.data.info("Confirm button tapped when deleting all data")

        do {
          for modelType in HDocContainer.allModelTypes {
            try deleteModleType(modelType)
          }
          Log.data.info("All data deleted")
          deleteResult = .success(())
        }
        catch {
          Log.data.info("When deleting all data, error occurred: \(error) ")
          deleteResult = .failure(error)
        }
      } label: {
        Text(HDocString.Common.ok)
      }

      Button(role: .cancel, action: {
        Log.data.info("Cancel button tapped when deleting all data")
      }, label: {
        Text(HDocString.Common.cancel)
      })
    } message: {
      Text(HDocString.Deletion.deleteAllDataConfirmText)
    }
    .alert(Text(deleteResultString), isPresented: .init(get: {
      deleteResult != nil
    }, set: { presented in
      if !presented {
        deleteResult = nil
      }
    })) {
      Button(role: .cancel) {} label: {
        Text(HDocString.Common.ok)
      }
    }
  }

  private var deleteResultString: LocalizedStringResource {
    switch deleteResult {
    case .success:
      return HDocString.Deletion.deleteSuccessLabel
    case .failure(let error):
      return HDocString.Deletion.deleteFailuerLabel(error)
    case nil:
      return ""
    }
  }

  private func deleteModleType(_ modelType: (some PersistentModel).Type) throws {
    try modelContext.delete(model: modelType)
  }
}

#Preview { @MainActor in
  NavigationStack {
    Form {
      AllDataDeletionCell()
    }
    .previewEnvironment()
  }
}
