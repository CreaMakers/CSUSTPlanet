//
//  MoocView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import SwiftUI

struct MoocView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isSSOLoggingIn {
            VStack {
                ProgressView("正在登录统一认证...")
                Text("请稍候")
                    .foregroundColor(.secondary)
            }
        } else if authManager.isMoocLoggingIn {
            VStack {
                ProgressView("正在登录网络课程中心...")
                Text("请稍候")
                    .foregroundColor(.secondary)
            }
        } else if authManager.isLoggedIn {
            Form {
                Section {
                    NavigationLink {
                        CoursesView(authManager: authManager)
                    } label: {
                        Label("课程列表", systemImage: "book.fill")
                    }
                }
            }
            .navigationTitle("网络课程中心")
        } else {
            NotLoginView()
        }
    }
}

#Preview {
    MoocView()
        .environmentObject(AuthManager())
}
