//
//  Tag.swift
//
//
//  Created by tigerguo on 2024/4/3.
//

import Foundation
import SwiftData

@Model
public final class Tag: Identifiable {
  public var text: String = ""
  public var comments: String = ""

  @Relationship(inverse: \Moment.tags)
  public var moments: [Moment]? = []
  public var uuid = UUID()
  public var creationDate = Date()

  /// Not used any more
  private var lastModifyDate = Date()

  public init(text: String, comments: String = "") {
    self.text = text
    self.comments = comments
    uuid = UUID()
    creationDate = Date()
//    lastModifyDate = creationDate
  }

  public var id: UUID {
    uuid
  }

  public var title: String {
    text
  }
}

extension Tag: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(text, forKey: .text)
    try container.encode(comments, forKey: .comments)
    try container.encode(uuid, forKey: .uuid)
    try container.encode(creationDate, forKey: .creationDate)
    try container.encode(lastModifyDate, forKey: .lastModifyDate)

    // relationship
    try container.encode(moments?.map { $0.uuid }, forKey: .moments)
  }

  private enum CodingKeys: CodingKey, CaseIterable {
    case text
    case comments
    case uuid
    case creationDate
    case lastModifyDate

    case moments
  }
}
