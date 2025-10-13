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
            cookies: AuthManager.shared.ssoHelper.getSession().sessionConfiguration.httpCookieStorage?.cookies
        )
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle("电费充值")
    }
}

#Preview {
    ElectricityRechargeView()
}
