//
//  ProfileView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var userManager: UserManager
    @State private var showLoginPopover = false

    var body: some View {
        Form {
            Section(header: Text("账号管理")) {
                if userManager.isLoggingIn {
                    HStack {
                        ProgressView()
                        Text("正在登录...")
                    }
                } else if let user = userManager.user {
                    NavigationLink {
                        ProfileDetailView()
                    } label: {
                        AsyncImage(url: URL(string: user.defaultUserAvatar)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }

                        VStack(alignment: .leading) {
                            Text("\(user.userName) \(user.userAccount)")
                                .font(.headline)
                            Text(user.deptName)
                                .font(.caption)
                        }
                    }
                    Button(action: {
                        Task {
                            try await userManager.logout()
                        }
                    }) {
                        Label("退出登录", systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .foregroundStyle(.red)
                        if userManager.isLoggingOut {
                            ProgressView()
                        }
                    }
                    .disabled(userManager.isLoggingOut)
                    .buttonStyle(PlainButtonStyle())
                } else {
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
        }
        .navigationTitle("我的")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(UserManager())
}
