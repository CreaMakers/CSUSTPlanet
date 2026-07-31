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
    @Bindable var authManager = AuthManager.shared
    @Bindable var globalManager = GlobalManager.shared

    @State var isLoginSheetPresented = false
    @State var isLogoutAlertPresented = false

    var body: some View {
        Form {
            Section {
                if let ssoProfile = authManager.ssoProfile {
                    NavigationLink(value: AppRoute.profile(.profileDetail)) {
                        HStack {
                            if let avatarUrl = URL(string: ssoProfile.avatar) {
                                let resource = KF.ImageResource(
                                    downloadURL: avatarUrl,
                                    cacheKey: avatarUrl.absoluteString.components(separatedBy: "?").first ?? ssoProfile.avatar
                                )
                                KFImage(source: .network(resource))
                                    .placeholder {
                                        ProgressView().smallControlSizeOnMac()
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
                            } else {
                                ProgressView().smallControlSizeOnMac()
                            }
                        }
                    }

                    HStack {
                        Button(action: { authManager.ssoRelogin(isSilent: false) }) {
                            Label("刷新统一身份认证登录", systemImage: "person.fill")
                        }
                        .disabled(!authManager.isSSOLoggedIn)
                        if authManager.isSSOLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    HStack {
                        Button(action: { authManager.educationLogin(isSilent: false) }) {
                            Label("刷新教务系统登录", systemImage: "graduationcap")
                        }
                        .disabled(!authManager.isSSOLoggedIn || authManager.isEducationLoggingIn)
                        if authManager.isEducationLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    HStack {
                        Button(action: { authManager.moocLogin(isSilent: false) }) {
                            Label("刷新网络课程中心登录", systemImage: "book.closed")
                        }
                        .disabled(!authManager.isSSOLoggedIn || authManager.isMoocLoggingIn)
                        if authManager.isMoocLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    HStack {
                        Button(action: { authManager.campusCardLogin(isSilent: false) }) {
                            Label("刷新校园卡系统登录", systemImage: "creditcard")
                        }
                        .disabled(!authManager.isSSOLoggedIn || authManager.isCampusCardLoggingIn)
                        if authManager.isCampusCardLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    Button(action: { isLogoutAlertPresented = true }) {
                        Label("退出登录", systemImage: "arrow.right.circle").foregroundColor(.red)
                    }
                    .disabled(authManager.isSSOLoggingOut)
                } else if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView().smallControlSizeOnMac()
                        Text("正在登录统一身份认证...")
                    }
                } else {
                    Button(action: { isLoginSheetPresented = true }) {
                        Label("登录统一认证账号", systemImage: "person.crop.circle.badge.plus")
                    }
                }
            } header: {
                Text("账号管理")
            }

            Section {
                Picker("外观主题", selection: $globalManager.appearance) {
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                    Text("跟随系统").tag("system")
                }

                NavigationLink(value: AppRoute.profile(.networkSettings)) {
                    Label("网络设置", systemImage: "network")
                }

                #if os(iOS)
                NavigationLink(value: AppRoute.profile(.backgroundTaskSettings)) {
                    Label("后台任务设置", systemImage: "gearshape.2")
                }
                #endif

                NavigationLink(value: AppRoute.profile(.notificationSettings)) {
                    Label("通知设置", systemImage: "bell.badge")
                }

                NavigationLink(value: AppRoute.profile(.widgetSettings)) {
                    Label("小组件设置", systemImage: "widget.small")
                }

                #if DEBUG
                NavigationLink(destination: DebugToolsView()) {
                    Label("调试工具", systemImage: "ladybug")
                }
                #endif
            } header: {
                Text("设置")
            }

            Section {
                NavigationLink(value: AppRoute.profile(.about(.main))) {
                    Text("关于 云岭星球")
                }

                NavigationLink(value: AppRoute.profile(.feedback)) {
                    Text("意见反馈")
                }

                NavigationLink(value: AppRoute.profile(.userAgreement)) {
                    Text("云岭星球 用户协议")
                }
            } header: {
                Text("帮助与支持")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("我的")
        .sheet(isPresented: $isLoginSheetPresented) {
            SSOLoginView()
        }
        .alert("退出登录", isPresented: $isLogoutAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive, action: { AuthManager.shared.ssoLogout() })
        } message: {
            Text("确定要退出登录吗？")
        }
    }
}
