//
//  PoemWidget.swift
//  PoemWidget
//
//  Created by huahuahu on 2022/5/2.
//

import Intents
import LibaiAppConstants
import LibaiModel
import SwiftData
import SwiftUI
import WidgetKit

struct Provider: IntentTimelineProvider {
  func placeholder(in _: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: PoemIntent(), poems: [.demo])
  }

  func getSnapshot(for configuration: PoemIntent, in _: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date(), configuration: configuration, poems: [.demo])
    completion(entry)
  }

  func getTimeline(for configuration: PoemIntent, in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let startOfToday = Calendar.current.startOfDay(for: Date())
    let entry = SimpleEntry(date: startOfToday.advanced(by: 24 * 60 * 60), configuration: configuration, poems: [])
    completion(Timeline(entries: [entry], policy: .atEnd))
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: PoemIntent
  let poems: [Poem]
}

struct PoemWidgetEntryView: View {
  let entry: Provider.Entry
//    var poem: CDPoem?
  @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)]) private var poems: FetchedResults<CDPoem>

  init(entry: Provider.Entry) {
    self.entry = entry
  }

  enum Constants {
    static let host = "www.libaiapp.com"
    static let poemDetailPath = "poemDetail"
  }

  private func url(for poemID: Int) -> URL? {
    var urlComponent = URLComponents()
    urlComponent.scheme = "https"
    urlComponent.host = Constants.host
    var url = urlComponent.url
    url = url?.appendingPathComponent(Constants.poemDetailPath)
    url = url?.appendingPathComponent("\(poemID)")
    return url
  }

//    @ViewBuilder
  func randomContentView(for poem: CDPoem) -> some View {
    let lines = poem.content.split { char in
      char.isNewline
    }.filter { !$0.isEmpty }

    let text: String = {
      if lines.isEmpty {
        return ""
      }
      if lines.count == 1 {
        return String(lines[0])
      }
      guard let randomStart = (0 ..< lines.count - 1).randomElement() else {
        return ""
      }
      return lines[randomStart ... randomStart + 1].joined(separator: "\n")
    }()

    return Text(text)
  }

  var body: some View {
    ZStack {
      ContainerRelativeShape()
        .fill(Color.primaryBackground)
      if let poem = poems.filter({ $0.genre.starts(with: "五言") }).randomElement() {
        VStack(spacing: 10) {
          Text(poem.title)
            .lineLimit(1)
            .truncationMode(.middle)
            .font(.headline)
          randomContentView(for: poem)
        }
        .widgetURL(url(for: poem.id))
      }
    }
    .foregroundColor(Color.primaryLabel)
    .padding()

//    .background(Color.primaryBackground)
  }
}

@main
struct PoemWidget: Widget {
  let kind: String = HWidgetKind.poems.kind

  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: PoemIntent.self, provider: Provider()) { entry in
      PoemWidgetEntryView(entry: entry)
        .environment(\.managedObjectContext, HCoreDataStack.shared.privateManagedContext)
    }
    .supportedFamilies([.systemMedium])
    .configurationDisplayName("每日一首")
    .description("随机浏览李白诗词")
  }
}

struct PoemWidget_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      PoemWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: PoemIntent(), poems: [.demo]))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
      PoemWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: PoemIntent(), poems: [.demo]))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .environment(\.colorScheme, .dark)

      PoemWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: PoemIntent(), poems: [.demo]))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .environment(\.colorScheme, .dark)
        .redacted(reason: .placeholder)
    }
  }
}
