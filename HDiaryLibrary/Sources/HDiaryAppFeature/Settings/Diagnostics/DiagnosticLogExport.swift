import CoreTransferable
import Foundation
import UniformTypeIdentifiers

nonisolated struct DiagnosticLogExport: Transferable, Sendable {
  let text: String

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .plainText) { item in
      Data(item.text.utf8)
    }
    .suggestedFileName("HDiary-Diagnostic-Logs.txt")
  }
}
