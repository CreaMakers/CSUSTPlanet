//
//  ProfileView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var globalVars: GlobalVars

    @State private var showLoginPopover = false
    @State private var showClearCacheAlert = false

    var body: some View {
        Form {
            Section(header: Text("账号管理")) {
                if let ssoProfile = authManager.ssoProfile {
                    NavigationLink {
                        ProfileDetailView(authManager: authManager)
                    } label: {
                        AsyncImage(url: URL(string: ssoProfile.defaultUserAvatar)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }

                        VStack(alignment: .leading) {
                            Text("\(ssoProfile.userName) \(ssoProfile.userAccount)")
                                .font(.headline)
                            Text(ssoProfile.deptName)
                                .font(.caption)
                        }
                    }
                    Button(action: {
                        Task {
                            try await authManager.logout()
                        }
                    }) {
                        Label("退出登录", systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .foregroundStyle(.red)
                        if authManager.isLoggingOut {
                            ProgressView()
                        }
                    }
                    .disabled(authManager.isLoggingOut)
                    .buttonStyle(PlainButtonStyle())
                } else if authManager.isLoggingIn {
                    HStack {
                        ProgressView()
                        Text("正在登录...")
                    }
                } else {
                    Button(action: {
                        showLoginPopover = true
                    }) {
                        Label("登录统一认证账号", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Section(header: Text("帮助与支持")) {
                NavigationLink {
                    HelpView()
                } label: {
                    Label("帮助中心", systemImage: "questionmark.circle")
                }
                NavigationLink {
                    AboutView()
                } label: {
                    Label("关于我们", systemImage: "info.circle")
                }
                NavigationLink {
                    FeedbackView()
                } label: {
                    Label("意见反馈", systemImage: "bubble.left.and.bubble.right")
                }
            }

            Section(header: Text("其他")) {
                Button {
                    showClearCacheAlert = true
                }
                label: {
                    Label("清除缓存", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .alert("清除缓存", isPresented: $showClearCacheAlert) {
                    Button("取消", role: .cancel) {}
                    Button("清除") {
                        authManager.clearCache()
                    }
                } message: {
                    Text("确定要清除所有缓存吗？这将删除所有的登录缓存数据。")
                }

                Picker(selection: $globalVars.appearance) {
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                    Text("跟随系统").tag("system")
                } label: {
                    Label("外观主题", systemImage: "paintbrush")
                }
            }
        }
        .popover(isPresented: $showLoginPopover) {
            SSOLoginView(showLoginPopover: $showLoginPopover)
        }
        .navigationTitle("我的")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(GlobalVars())
}
