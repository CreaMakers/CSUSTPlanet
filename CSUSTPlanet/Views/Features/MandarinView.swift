//
//  MandarinView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct MandarinView: View {
    var body: some View {
        WebView(url: URL(string: "https://zwfw.moe.gov.cn/mandarin/")!)
            .navigationTitle("普通话查询")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MandarinView()
}
