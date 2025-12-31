//
//  FeedbackView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

struct FeedbackView: View {
    var body: some View {
        Form {
            if let feedbackMarkdown = AssetUtil.loadMarkdownFile(named: "Feedback") {
                Markdown(feedbackMarkdown)
            } else {
                Text("无法加载反馈内容")
            }
        }
        .navigationTitle("意见反馈")
        .trackView("Feedback")
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}
