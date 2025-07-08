//
//  ProfileView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct ProfileView: View {
    @State private var showLoginPopover = false

    var body: some View {
        Form {
            Section(header: Text("账号管理")) {
                Button(action: {
                    showLoginPopover = true
                }) {
                    Label("登录统一认证账号", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showLoginPopover) {
                    SSOLoginView(showLoginPopover: $showLoginPopover)
                }
            }
            Section(header: Text("帮助与支持")) {
                NavigationLink {} label: {
                    Label("帮助中心", systemImage: "questionmark.circle")
                }
                NavigationLink {} label: {
                    Label("关于我们", systemImage: "info.circle")
                }
                NavigationLink {} label: {
                    Label("意见反馈", systemImage: "bubble.left.and.bubble.right")
                }
            }
        }
        .navigationTitle("我的")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
