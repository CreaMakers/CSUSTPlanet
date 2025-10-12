//
//  TesterListView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/24.
//

import MarkdownUI
import SwiftUI

struct TesterListView: View {
    let testers: [(name: String, joinDate: String)] = [
        ("Zhe_Learn", "2025-07-07"),
        ("kdodh", "2025-07-12"),
        ("a2a", "2025-07-12"),
        ("嗯嗯", "2025-07-19"),
        ("kina_美晴", "2025-07-20"),
        ("强溯", "2025-07-24"),
    ]

    var body: some View {
        Form {
            if let descriptionMarkdown = AssetUtils.loadMarkdownFile(named: "TesterListDescription") {
                Markdown(descriptionMarkdown)
            } else {
                Text("无法加载内测成员列表说明")
            }

            Section(header: Text("内测成员列表")) {
                ForEach(testers, id: \.name) { tester in
                    HStack {
                        Text(tester.name)
                        Spacer()
                        Text(tester.joinDate)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("内测成员列表")
    }
}

#Preview {
    NavigationStack {
        TesterListView()
    }
}
