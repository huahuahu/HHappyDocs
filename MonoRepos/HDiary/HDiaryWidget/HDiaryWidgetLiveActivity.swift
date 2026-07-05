////
////  HDiaryWidgetLiveActivity.swift
////  HDiaryWidget
////
////  Created by tigerguo on 2023/7/14.
////
//
// import ActivityKit
// import WidgetKit
// import SwiftUI
//
// struct HDiaryWidgetAttributes: ActivityAttributes {
//    public struct ContentState: Codable, Hashable {
//        // Dynamic stateful properties about your activity go here!
//        var emoji: String
//    }
//
//    // Fixed non-changing properties about your activity go here!
//    var name: String
// }
//
// struct HDiaryWidgetLiveActivity: Widget {
//    var body: some WidgetConfiguration {
//        ActivityConfiguration(for: HDiaryWidgetAttributes.self) { context in
//            // Lock screen/banner UI goes here
//            VStack {
//                Text("Hello \(context.state.emoji)")
//            }
//            .activityBackgroundTint(Color.cyan)
//            .activitySystemActionForegroundColor(Color.black)
//
//        } dynamicIsland: { context in
//            DynamicIsland {
//                // Expanded UI goes here.  Compose the expanded UI through
//                // various regions, like leading/trailing/center/bottom
//                DynamicIslandExpandedRegion(.leading) {
//                    Text("Leading")
//                }
//                DynamicIslandExpandedRegion(.trailing) {
//                    Text("Trailing")
//                }
//                DynamicIslandExpandedRegion(.bottom) {
//                    Text("Bottom \(context.state.emoji)")
//                    // more content
//                }
//            } compactLeading: {
//                Text("L")
//            } compactTrailing: {
//                Text("T \(context.state.emoji)")
//            } minimal: {
//                Text(context.state.emoji)
//            }
//            .widgetURL(URL(string: "http://www.apple.com"))
//            .keylineTint(Color.red)
//        }
//    }
// }
//
// extension HDiaryWidgetAttributes {
//    fileprivate static var preview: HDiaryWidgetAttributes {
//        HDiaryWidgetAttributes(name: "World")
//    }
// }
//
// extension HDiaryWidgetAttributes.ContentState {
//    fileprivate static var smiley: HDiaryWidgetAttributes.ContentState {
//        HDiaryWidgetAttributes.ContentState(emoji: "😀")
//     }
//
//     fileprivate static var starEyes: HDiaryWidgetAttributes.ContentState {
//         HDiaryWidgetAttributes.ContentState(emoji: "🤩")
//     }
// }
//
// #Preview("Notification", as: .content, using: HDiaryWidgetAttributes.preview) {
//   HDiaryWidgetLiveActivity()
// } contentStates: {
//    HDiaryWidgetAttributes.ContentState.smiley
//    HDiaryWidgetAttributes.ContentState.starEyes
// }
