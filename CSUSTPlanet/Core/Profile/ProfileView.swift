//
//  ProfileView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import ActivityKit
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalVars: GlobalVars

    @State private var showLoginSheet = false

    var body: some View {
        Form {
            Section(header: Text("账号管理")) {
                if let ssoProfile = authManager.ssoProfile {
                    NavigationLink {
                        ProfileDetailView(authManager: authManager)
                    } label: {
                        HStack {
                            AsyncImage(url: URL(string: ssoProfile.avatar)) { image in
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
                    }

                    if authManager.isEducationLoggingIn {
                        Button(action: authManager.loginToEducation) {
                            HStack {
                                ProgressView().padding(.horizontal, 6).id(authManager.eduLoginID)
                                Text("正在登录教务系统 (点击重试)")
                            }
                        }
                    } else {
                        Button(action: authManager.loginToEducation) {
                            ColoredLabel(title: "重新登录教务系统", iconName: "graduationcap", color: .orange)
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isLoggedIn)
                    }

                    if authManager.isMoocLoggingIn {
                        Button(action: authManager.loginToMooc) {
                            HStack {
                                ProgressView().padding(.horizontal, 6).id(authManager.moocLoginID)
                                Text("正在登录网络课程中心 (点击重试)")
                            }
                        }
                    } else {
                        Button(action: authManager.loginToMooc) {
                            ColoredLabel(title: "重新登录网络课程中心", iconName: "book.closed", color: .mint)
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isLoggedIn)
                    }

                    Button(action: {
                        Task {
                            try await authManager.logout()
                        }
                    }) {
                        HStack {
                            ColoredLabel(title: "退出登录", iconName: "arrow.right.circle", color: .red)
                            if authManager.isSSOLoggingOut {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(authManager.isSSOLoggingOut)
                    .buttonStyle(PlainButtonStyle())
                } else if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView()
                        Text("正在登录...")
                    }
                } else {
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        ColoredLabel(title: "登录统一认证账号", iconName: "person.crop.circle.badge.plus", color: .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Section(header: Text("设置"), footer: Text("实时活动/灵动岛将会显示：上课前20分钟、上课中和下课后5分钟的课程状态")) {
                Picker(selection: $globalVars.appearance) {
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                    Text("跟随系统").tag("system")
                } label: {
                    ColoredLabel(title: "外观主题", iconName: "paintbrush", color: .purple)
                }

                Toggle(isOn: $globalVars.isLiveActivityEnabled) {
                    ColoredLabel(title: "启用实时活动/灵动岛", iconName: "bolt.circle", color: .yellow)
                }
                .onChange(of: globalVars.isLiveActivityEnabled, { _, _ in ActivityManager.shared.autoUpdateActivity() })
            }

            Section(header: Text("帮助与支持")) {
                NavigationLink {
                    AboutView()
                } label: {
                    ColoredLabel(title: "关于", iconName: "info.circle", color: .teal)
                }

                NavigationLink {
                    FeedbackView()
                } label: {
                    ColoredLabel(title: "意见反馈", iconName: "bubble.left.and.bubble.right", color: .green)
                }

                NavigationLink {
                    UserAgreementView()
                } label: {
                    ColoredLabel(title: "用户协议", iconName: "doc.text", color: .indigo)
                }
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            SSOLoginView(isShowingLoginSheet: $showLoginSheet)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(GlobalVars.shared)
}
