//
//  CourseStatusWidgetLiveActivity.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct CourseStatusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {

    }
}

struct CourseStatusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CourseStatusWidgetAttributes.self) { context in
            Text("Hello World")
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }

                DynamicIslandExpandedRegion(.center) {
                    Text("Center")
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                }
            } compactLeading: {
                Text("Leading")
            } compactTrailing: {
                Text("Trailing")
            } minimal: {
                Text("Mini")
            }
        }
    }
}

#Preview("Notification", as: .content, using: CourseStatusWidgetAttributes()) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState()
}
