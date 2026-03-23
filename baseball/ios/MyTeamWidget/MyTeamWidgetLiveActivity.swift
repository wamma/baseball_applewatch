//
//  MyTeamWidgetLiveActivity.swift
//  MyTeamWidget
//
//  Created by hyung jun on 3/20/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MyTeamWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MyTeamWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyTeamWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MyTeamWidgetAttributes {
    fileprivate static var preview: MyTeamWidgetAttributes {
        MyTeamWidgetAttributes(name: "World")
    }
}

extension MyTeamWidgetAttributes.ContentState {
    fileprivate static var smiley: MyTeamWidgetAttributes.ContentState {
        MyTeamWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MyTeamWidgetAttributes.ContentState {
         MyTeamWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MyTeamWidgetAttributes.preview) {
   MyTeamWidgetLiveActivity()
} contentStates: {
    MyTeamWidgetAttributes.ContentState.smiley
    MyTeamWidgetAttributes.ContentState.starEyes
}
