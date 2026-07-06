//
//  Participant.swift
//
//
//  Created by tigerguo on 2024/4/3.
//

#if os(iOS)

import Foundation
import SwiftData
#if canImport(UIKit)
  import UIKit
#endif

@Model
public final class Participant {
  public var name: String = ""
  public var nickName: String = ""
  public var avatar: Data?

  public var note: String = ""
  @Relationship(inverse: \Moment.participants)
  public var moments: [Moment]?
  public private(set) var uuid: UUID = UUID()
  public private(set) var creationDate = Date()

  public static func create(name: String,
                            nickName: String,
                            note: String? = nil,
                            avatar: Data? = nil) -> Self {
    Self(name: name, nickName: nickName, note: note, avatar: avatar)
  }

  init(name: String,
       nickName: String,
       note: String? = nil,
       avatar: Data? = nil) {
    self.name = name
    self.nickName = nickName
    self.note = note ?? ""
    self.avatar = avatar
    self.creationDate = Date()
    self.uuid = UUID()
  }

  #if canImport(UIKit)
    public func getAvatarImage() -> UIImage {
      if let avatar {
        return UIImage(data: avatar) ?? UIImage(resource: .defaultPerson)
      }
      else {
        return UIImage(resource: .defaultPerson)
      }
    }
  #endif
}

extension Participant: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(name, forKey: .name)
    try container.encode(nickName, forKey: .nickName)
    try container.encode(avatar, forKey: .avatar)
    try container.encode(note, forKey: .note)
    try container.encode(uuid, forKey: .uuid)
    try container.encode(creationDate, forKey: .creationDate)

    // relationship
    try container.encode(moments?.map { $0.uuid }, forKey: .moments)
  }

  private enum CodingKeys: CodingKey, CaseIterable {
    case name
    case nickName
    case avatar
    case note
    case uuid
    case creationDate

    case moments
  }
}

#endif
