//
//  ProfileSplitView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import SwiftUI

struct ProfileSplitView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalVars: GlobalVars

    @State private var showLoginSheet = false
    @State var selectedSection: ProfileSection? = nil

    enum ProfileSection: Hashable {
        case detail, about, feedback, agreement
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                Section("账号管理") {
                    if let ssoProfile = authManager.ssoProfile {
                        NavigationLink(value: ProfileSection.detail) {
                            HStack {
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
                        .buttonStyle(.plain)
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
                        .buttonStyle(.plain)
                    }
                }
                Section("帮助与支持") {
                    NavigationLink(value: ProfileSection.about) {
                        ColoredLabel(title: "关于", iconName: "info.circle", color: .teal)
                    }
                    NavigationLink(value: ProfileSection.feedback) {
                        ColoredLabel(title: "意见反馈", iconName: "bubble.left.and.bubble.right", color: .green)
                    }
                    NavigationLink(value: ProfileSection.agreement) {
                        ColoredLabel(title: "用户协议", iconName: "doc.text", color: .indigo)
                    }
                }
                Section("其他") {
                    Picker(selection: $globalVars.appearance) {
                        Text("浅色模式").tag("light")
                        Text("深色模式").tag("dark")
                        Text("跟随系统").tag("system")
                    } label: {
                        ColoredLabel(title: "外观主题", iconName: "paintbrush", color: .purple)
                    }

                    Button(action: authManager.loginToEducation) {
                        HStack {
                            ColoredLabel(title: "重新登录教务系统", iconName: "graduationcap", color: .orange)
                            if authManager.isEducationLoggingIn {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(authManager.isEducationLoggingIn || !authManager.isLoggedIn)
                    .buttonStyle(.plain)

                    Button(action: authManager.loginToMooc) {
                        HStack {
                            ColoredLabel(title: "重新登录网络课程中心", iconName: "book.closed", color: .mint)
                            if authManager.isMoocLoggingIn {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(authManager.isMoocLoggingIn || !authManager.isLoggedIn)
                    .buttonStyle(.plain)
                }
            }
        } detail: {
            switch selectedSection {
            case .detail:
                ProfileDetailView(authManager: authManager)
            case .about:
                AboutView()
            case .feedback:
                FeedbackView()
            case .agreement:
                UserAgreementView()
            case nil:
                Text("请选择一个选项")
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            NavigationStack {
                SSOLoginView(authManager: authManager, isShowingLoginSheet: $showLoginSheet)
            }
        }
    }
}

#Preview {
    ProfileSplitView()
}
