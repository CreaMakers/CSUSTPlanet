//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct SSOLoginView: View {
    @EnvironmentObject var userManager: UserManager

    @Binding var showLoginPopover: Bool
    @State private var selectedTab = 0

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword = false

    @State private var captcha: String = ""
    @State private var smsCode: String = ""

    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    @State private var captchaImageData: Data? = nil

    @State private var countdown = 0

    var body: some View {
        VStack(spacing: 30) {
            Text("统一认证登录")
                .font(.title)
                .fontWeight(.bold)

            HStack(alignment: .center) {
                Picker("登录方式", selection: $selectedTab) {
                    Text("账号登录").tag(0)
                    Text("验证码登录").tag(1)
                }
                .pickerStyle(.segmented)

                Button(action: {
                    showLoginPopover = false
                }) {
                    Text("关闭")
                }
            }
            .padding(.horizontal)

            TabView(selection: $selectedTab) {
                accountLoginView.tag(0)
                verificationCodeLoginView.tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .padding(.top, 25)
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            loadCaptcha()
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
                TextField("请输入账号", text: $username)
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

                if showPassword {
                    TextField("请输入密码", text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .frame(height: 20)
                } else {
                    SecureField("请输入密码", text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .frame(height: 20)
                        .autocorrectionDisabled(true)
                }

                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
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

            Button(action: handleAccountLogin) {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                if userManager.isLoggingIn {
                    ProgressView()
                }
            }
            .disabled(username.isEmpty || password.isEmpty || userManager.isLoggingIn)
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
                TextField("请输入账号", text: $username)
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
                    TextField("请输入图片验证码", text: $captcha)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(height: 20)

                    if let data = captchaImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                            .onTapGesture {
                                loadCaptcha()
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
                    TextField("请输入短信验证码", text: $smsCode)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(height: 20)
                    Button(action: handleGetDynamicCode) {
                        Text(countdown > 0 ? "\(countdown)秒后重新获取" : "获取验证码")
                    }
                    .disabled(captcha.isEmpty || username.isEmpty || countdown > 0)
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

            Button(action: handleDynamicLogin) {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                if userManager.isLoggingIn {
                    ProgressView()
                }
            }
            .disabled(username.isEmpty || captcha.isEmpty || smsCode.isEmpty || userManager.isLoggingIn)
            .padding(.horizontal)
            .padding(.top, 5)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Actions

    func handleAccountLogin() {
        Task {
            do {
                try await userManager.login(username: username, password: password)
                showLoginPopover = false
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true

                debugPrint(error)
            }
        }
    }

    func loadCaptcha() {
        Task {
            do {
                captchaImageData = try await userManager.getCaptcha()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true

                debugPrint(error)
            }
        }
    }

    func handleGetDynamicCode() {
        Task {
            do {
                try await userManager.getDynamicCode(username: username, captcha: captcha)
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true

                debugPrint(error)
            }
            countdown = 120
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if countdown > 1 {
                    countdown -= 1
                } else {
                    timer.invalidate()
                    countdown = 0
                }
            }
        }
    }

    func handleDynamicLogin() {
        Task {
            do {
                try await userManager.dynamicLogin(username: username, captcha: captcha, dynamicCode: smsCode)
                showLoginPopover = false
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true

                debugPrint(error)
            }
        }
    }
}

#Preview {
    SSOLoginView(showLoginPopover: .constant(true))
        .environmentObject(UserManager())
}
