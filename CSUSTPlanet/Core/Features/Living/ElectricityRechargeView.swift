//
//  ElectricityRechargeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/13.
//

import SwiftUI

struct ElectricityRechargeView: View {
    var body: some View {
        WebView(
            url: URL(string: "https://hxyxh5.csust.edu.cn/plat/shouyeUser")!,
            cookies: CookieHelper.shared.session.sessionConfiguration.httpCookieStorage?.cookies
        )
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle("电费充值")
        .trackView("ElectricityRecharge")
    }
}

#Preview {
    ElectricityRechargeView()
}
