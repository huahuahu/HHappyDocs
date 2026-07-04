//
//  FeedbackSender.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/7.
//

import CloudKit
import Foundation

struct FeedbackSender {
  enum Constants {
    static let contentICloudKey = "content"
    static let modelICloudKey = "model"
    static let versionICloudKey = "version"
    static let dateICloudKey = "date"
  }

  func sendFeedback(_ content: String) async throws {
    let feedback = FeedbackModel(content: content)

    let record = CKRecord(recordType: ICloudConstants.feedBackRecordName)
    record[Constants.contentICloudKey] = feedback.content
    record[Constants.modelICloudKey] = feedback.model
    record[Constants.versionICloudKey] = feedback.version
    record[Constants.dateICloudKey] = Date()
    do {
      try await ICloudConstants.publicDatabase.save(record)
      dataLog("send feedback succ")
    }
    catch {
      dataLog("send feedback \(error)")
    }
  }
}
