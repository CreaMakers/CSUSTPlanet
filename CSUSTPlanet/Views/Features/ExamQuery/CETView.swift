//
//  CETView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct CETView: View {
    var body: some View {
        WebView(url: URL(string: "https://cjcx.neea.edu.cn/html1/folder/21033/653-1.htm")!)
            .navigationTitle("四六级查询")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CETView()
}
