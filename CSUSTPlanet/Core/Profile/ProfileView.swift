//
//  ProfileView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import ActivityKit
import Kingfisher
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var GlobalManager: GlobalManager
    @EnvironmentObject var notificationHelper: NotificationHelper

    @State private var isLoginSheetPresented = false
    @State private var isWebVPNSheetPresented = false
    @State private var isWebVPNDisableAlertPresented = false

    var body: some View {
        let webVPNToggleBinding = Binding<Bool>(
            get: { GlobalManager.isWebVPNModeEnabled },
            set: { newValue in
                if newValue == true && !GlobalManager.isWebVPNModeEnabled {
                    isWebVPNSheetPresented = true
                } else if newValue == false && GlobalManager.isWebVPNModeEnabled {
                    isWebVPNDisableAlertPresented = true
                } else {
                    GlobalManager.isWebVPNModeEnabled = newValue
                }
            }
        )

        Form {
            Section(header: Text("账号管理")) {
                if let ssoProfile = authManager.ssoProfile {
                    NavigationLink {
                        ProfileDetailView(authManager: authManager)
                    } label: {
                        HStack {
                            let avatarUrl = URL(string: ssoProfile.avatar)
                            let resource = avatarUrl.map { url in
                                KF.ImageResource(
                                    downloadURL: url,
                                    cacheKey: url.absoluteString.components(separatedBy: "?").first ?? ssoProfile.avatar
                                )
                            }
                            KFImage(source: resource != nil ? .network(resource!) : nil)
                                .placeholder {
                                    ProgressView()
                                        .frame(width: 40, height: 40)
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text("\(ssoProfile.userName) \(ssoProfile.userAccount)")
                                    .font(.headline)
                                Text(ssoProfile.deptName)
                                    .font(.caption)
                            }
                        }
                    }

                    if authManager.isSSOLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录统一身份认证...")
                        }
                    } else {
                        Button(action: authManager.ssoRelogin) {
                            HStack {
                                ColoredLabel(title: "重新登录统一身份认证", iconName: "person.fill", color: .blue)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isSSOLoggedIn)
                    }

                    if authManager.isEducationLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录教务系统...")
                        }
                    } else {
                        Button(action: authManager.educationLogin) {
                            HStack {
                                ColoredLabel(title: "重新登录教务系统", iconName: "graduationcap", color: .orange)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isSSOLoggedIn)
                    }

                    if authManager.isMoocLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录网络课程中心...")
                        }
                    } else {
                        Button(action: authManager.moocLogin) {
                            HStack {
                                ColoredLabel(title: "重新登录网络课程中心", iconName: "book.closed", color: .mint)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isSSOLoggedIn)
                    }

                    Button(action: authManager.ssoLogout) {
                        HStack {
                            ColoredLabel(title: "退出登录", iconName: "arrow.right.circle", color: .red)
                            Spacer()
                            if authManager.isSSOLoggingOut {
                                ProgressView()
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(authManager.isSSOLoggingOut)
                    .buttonStyle(PlainButtonStyle())
                } else if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView()
                        Text("正在登录统一身份认证...")
                    }
                } else {
                    Button(action: {
                        isLoginSheetPresented = true
                    }) {
                        HStack {
                            ColoredLabel(title: "登录统一认证账号", iconName: "person.crop.circle.badge.plus", color: .blue)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Section(header: Text("设置"), footer: Text("实时活动/灵动岛将会显示：上课前20分钟、上课中和下课后5分钟的课程状态")) {
                Picker(selection: $GlobalManager.appearance) {
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                    Text("跟随系统").tag("system")
                } label: {
                    ColoredLabel(title: "外观主题", iconName: "paintbrush", color: .purple)
                }

                Toggle(isOn: webVPNToggleBinding) {
                    ColoredLabel(title: "开启WebVPN模式（实验）", iconName: "globe", color: .orange)
                }

                Toggle(isOn: $GlobalManager.isNotificationEnabled) {
                    ColoredLabel(title: "开启通知", iconName: "bell", color: .green)
                }
                .onChange(of: GlobalManager.isNotificationEnabled, { _, _ in NotificationHelper.shared.toggle() })

                Toggle(isOn: $GlobalManager.isLiveActivityEnabled) {
                    ColoredLabel(title: "启用实时活动/灵动岛", iconName: "bolt.circle", color: .yellow)
                }
                .onChange(of: GlobalManager.isLiveActivityEnabled, { _, _ in ActivityManager.shared.autoUpdateActivity() })
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
        .sheet(isPresented: $isLoginSheetPresented) {
            SSOLoginView(isShowingLoginSheet: $isLoginSheetPresented)
        }
        .sheet(isPresented: $isWebVPNSheetPresented) {
            WebVPNGuideView(isPresented: $isWebVPNSheetPresented)
        }
        .alert("关闭 WebVPN 模式", isPresented: $isWebVPNDisableAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("关闭并重启", role: .destructive) {
                GlobalManager.isWebVPNModeEnabled = false
                exit(0)
            }
        } message: {
            Text("关闭 WebVPN 模式需要重启应用才能生效。")
        }
        .alert("错误", isPresented: $notificationHelper.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(notificationHelper.errorDescription)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(GlobalManager.shared)
    .environmentObject(NotificationHelper.shared)
}
