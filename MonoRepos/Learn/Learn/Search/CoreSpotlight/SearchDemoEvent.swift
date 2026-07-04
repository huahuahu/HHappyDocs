//
//  SearchDemoEvent.swift
//  Learn
//
//  Created by tigerguo on 2025/1/24.
//

import Foundation

extension SearchDemo {
  struct Event: Identifiable {
    let id: UUID
    let person: String
    let title: String
    let tag: String
    let description: String
    let contentURL: URL?

    init(
      id: UUID,
      person: String,
      title: String,
      tag: String,
      description: String,
      contentURL: URL? = nil
    ) {
      self.id = id
      self.person = person
      self.title = title
      self.tag = tag
      self.description = description
      self.contentURL = contentURL
    }

    private static let sampleTextUrl = Bundle.main.url(forResource: "sample", withExtension: "text")!
    static let sampleImageUrl = Bundle.main.url(forResource: "sample", withExtension: "png")!

    static let testEvents: [Self] = [
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075539D")!, person: "John Doe", title: "会议", tag: "meeting", description: "第一季度项目进展汇报", contentURL: sampleTextUrl),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075539E")!, person: "Jane Smith", title: "Project Review", tag: "tag", description: "Q1 project status review", contentURL: sampleImageUrl),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075539F")!, person: "Tiger Guo", title: "Sun and Moon", tag: "sematic", description: "sun and moon in the sky"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075540A")!, person: "张三", title: "产品设计评审", tag: "design", description: "新功能原型设计讨论"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075540B")!, person: "Lisa Wong", title: "Team Building", tag: "social", description: "Annual team building event at Central Park"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075540C")!, person: "王五", title: "技术分享", tag: "tech", description: "SwiftUI 最佳实践分享会"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075540D")!, person: "Mike Chen", title: "Code Review", tag: "development", description: "Review pull request for new features"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075540E")!, person: "Sarah Johnson", title: "User Research", tag: "research", description: "Interview with key users about new features"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-860F3075540F")!, person: "李四", title: "市场策略", tag: "marketing", description: "讨论下半年市场推广方案"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-8603075541AE")!, person: "David Miller", title: "Budget Planning", tag: "finance", description: "Annual budget review and planning"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-8603075541BA")!, person: "赵六", title: "客户会谈", tag: "client", description: "与重要客户讨论合作方案"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-8603075541CA")!, person: "Emma Wilson", title: "UI Design", tag: "design", description: "New interface design workshop"),
      Self(id: UUID(uuidString: "81BB0D9A-EA7D-43D8-8583-8603075541DD")!, person: "陈明", title: "数据分析", tag: "analytics", description: "用户行为数据分析报告"),
    ]
  }
}
