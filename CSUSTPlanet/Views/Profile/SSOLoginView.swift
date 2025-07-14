//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct SSOLoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: SSOLoginViewModel

    init(authManager: AuthManager, isShowingLoginSheet: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: SSOLoginViewModel(authManager: authManager, isShowingLoginSheet: isShowingLoginSheet))
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("统一认证登录")
                .font(.title)
                .fontWeight(.bold)

            HStack(alignment: .center) {
                Picker("登录方式", selection: $viewModel.selectedTab) {
                    Text("账号登录").tag(0)
                    Text("验证码登录").tag(1)
                }
                .pickerStyle(.segmented)

                Button(action: viewModel.closeLoginSheet) {
                    Text("关闭")
                }
            }
            .padding(.horizontal)

            TabView(selection: $viewModel.selectedTab) {
                accountLoginView.tag(0)
                verificationCodeLoginView.tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .padding(.top, 25)
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            viewModel.handleRefreshCaptcha()
        }
    }

    // MARK: - Account Login View

    private var accountLoginView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundColor(.gray)
                TextField("请输入账号", text: $viewModel.username)
                    .textFieldStyle(.plain)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 5)

            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundColor(.gray)

                if viewModel.isPasswordVisible {
                    TextField("请输入密码", text: $viewModel.password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .frame(height: 20)
                } else {
                    SecureField("请输入密码", text: $viewModel.password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .frame(height: 20)
                        .autocorrectionDisabled(true)
                }

                Button(action: {
                    viewModel.isPasswordVisible.toggle()
                }) {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)

            Button(action: viewModel.handleAccountLogin) {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                if authManager.isSSOLoggingIn {
                    ProgressView()
                }
            }
            .disabled(viewModel.isAccountLoginDisabled)
            .padding(.horizontal)
            .padding(.top, 5)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Verification Code Login View

    private var verificationCodeLoginView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundColor(.gray)
                TextField("请输入账号", text: $viewModel.username)
                    .textFieldStyle(.plain)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 5)

            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundColor(.gray)
                    TextField("请输入图片验证码", text: $viewModel.captcha)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(height: 20)

                    if let data = viewModel.captchaImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                            .onTapGesture {
                                viewModel.handleRefreshCaptcha()
                            }
                    } else {
                        ProgressView()
                            .frame(height: 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundColor(.gray)
                    TextField("请输入短信验证码", text: $viewModel.smsCode)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(height: 20)
                    Button(action: viewModel.handleGetDynamicCode) {
                        Text(viewModel.countdown > 0 ? "\(viewModel.countdown)秒后重新获取" : "获取验证码")
                    }
                    .disabled(viewModel.isGetDynamicCodeDisabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            .padding(.horizontal)

            Button(action: viewModel.handleDynamicLogin) {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                if authManager.isSSOLoggingIn {
                    ProgressView()
                }
            }
            .disabled(viewModel.isDynamicLoginDisabled)
            .padding(.horizontal)
            .padding(.top, 5)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

#Preview {
    SSOLoginView(authManager: AuthManager(), isShowingLoginSheet: .constant(true))
}
