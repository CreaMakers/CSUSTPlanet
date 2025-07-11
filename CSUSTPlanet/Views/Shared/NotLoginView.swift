//
//  NotLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct NotLoginView: View {
    @EnvironmentObject private var globalVars: GlobalVars

    var body: some View {
        VStack {
            Text("请先登录")
                .font(.largeTitle)
                .padding()
            HStack {
                Text("前往")
                Button(action: {
                    globalVars.selectedTab = 1
                }) {
                    Text("登录")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    NotLoginView()
}
