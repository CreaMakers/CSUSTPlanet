//
//  FeedbackView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

let feedbackMarkdown = """
您的反馈对我们非常重要！如果您在使用 **长理星球** 时遇到问题，或有任何建议，欢迎通过以下方式联系我们：  

📧 **邮箱反馈**：[developer@zhelearn.com](mailto:developer@zhelearn.com)  
📢 **QQ交流群**：[125010161](mqqapi://card/show_pslcard?src_type=internal&version=1&uin=125010161&key=&card_type=group&source=external)  

无论是功能建议、BUG 报告，还是使用体验上的优化意见，我们都会认真阅读并持续改进！感谢您的支持！ 🚀
"""

struct FeedbackView: View {
    var body: some View {
        ScrollView {
            Markdown(feedbackMarkdown)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding()
        }
        .navigationTitle("意见反馈")
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}
