//
//  WebVPNConverterView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/14.
//

import AlertToast
import CSUSTKit
import SwiftUI

enum ConversionMode: String, CaseIterable, Identifiable {
    case convert = "转换"
    case restore = "还原"
    var id: Self { self }
}

struct WebVPNConverterView: View {
    // MARK: - State Properties

    @Environment(\.openURL) private var openURL

    @State private var selectedMode: ConversionMode = .convert
    @State private var originalUrl: String = ""
    @State private var resultUrl: String = ""
    @State private var isErrorPresented: Bool = false

    @State private var successToast: ToastState = .successTitle

    // MARK: - Computed Properties for UI

    private var inputTitle: String {
        selectedMode == .convert ? "原始链接" : "WebVPN 链接"
    }

    private var inputPlaceholder: String {
        selectedMode == .convert ? "请输入或粘贴需要转换的链接" : "请输入或粘贴需要还原的链接"
    }

    private var outputTitle: String {
        selectedMode == .convert ? "WebVPN 链接" : "原始链接"
    }

    private var outputPlaceholder: String {
        "\(selectedMode.rawValue)结果将显示在此处"
    }

    // MARK: - Body

    var body: some View {
        CustomScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: Mode Picker

                Picker("选择模式", selection: $selectedMode) {
                    ForEach(ConversionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                // MARK: Input Section

                Text(inputTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    TextField(inputPlaceholder, text: $originalUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                        #if os(iOS)
                    .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled(true)

                    if !originalUrl.isEmpty {
                        Button(action: {
                            originalUrl = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 4)
                        .transition(.opacity.animation(.easeInOut))
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                // MARK: Output Section

                Text(outputTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                CustomGroupBox {
                    if resultUrl.isEmpty {
                        Text(outputPlaceholder)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            if isErrorPresented {
                                Text(resultUrl)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                                    .textSelection(.enabled)
                            } else {
                                Button(action: openResultInBrowser) {
                                    Text(resultUrl)
                                        .foregroundColor(.blue)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            if !isErrorPresented {
                                Button(action: copyToClipboard) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity.animation(.easeInOut))
                    }
                }

                // MARK: - Explanation Section

                Divider()
                    .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 12) {
                    Text("功能说明")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WebVPN 转换与还原")
                            .font(.subheadline)
                            .bold()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("**转换**：")
                                .font(.footnote)
                            Text("将普通的互联网网址（如 `baidu.com`）或校内IP地址（如 `10.2.3.4`）转换为可通过校园 WebVPN 在校外访问的专属链接。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                            Text("方便您在校外直接访问仅限内网使用的学术资源、内网系统等。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("**还原**：")
                                .font(.footnote)
                                .padding(.top, 4)
                            Text("将 WebVPN 格式的链接还原为原始的网址或IP地址。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                            Text("当您收到一个 WebVPN 链接，但不确定其原始地址时，此功能可以帮助您快速解析。")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                        }
                    }
                }
            }
            .padding()
            .onChange(of: originalUrl) { _, newValue in
                DispatchQueue.main.async {
                    withAnimation {
                        performConversion(from: newValue)
                    }
                }
            }
            .onChange(of: selectedMode) { _, _ in
                originalUrl = ""
            }
        }
        .navigationTitle("WebVPN 转换")
        .successToast($successToast)
    }

    // MARK: - Private Methods

    private func performConversion(from urlString: String) {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            resultUrl = ""
            isErrorPresented = false
            return
        }

        var urlString = urlString
        if let u = URL(string: urlString), u.scheme == nil {
            if urlString.hasPrefix("//") {
                urlString = "http:" + urlString
            } else {
                urlString = "http://" + urlString
            }
        }
        guard let url = URL(string: urlString), url.host != nil, url.scheme != nil else {
            resultUrl = "无效的 URL 或无法获取主机名/协议"
            isErrorPresented = true
            return
        }

        do {
            switch selectedMode {
            case .convert:
                resultUrl = try WebVPNHelper.encryptURL(url).absoluteString
            case .restore:
                resultUrl = try WebVPNHelper.decryptURL(url).absoluteString
            }
            isErrorPresented = false
        } catch {
            resultUrl = "\(selectedMode.rawValue)失败: \(error.localizedDescription)"
            isErrorPresented = true
        }
    }

    private func copyToClipboard() {
        #if os(iOS)
        PlatformPasteboard.general.string = resultUrl
        #elseif os(macOS)
        PlatformPasteboard.general.clearContents()
        PlatformPasteboard.general.setString(resultUrl, forType: .string)
        #endif
        successToast.show(message: "已复制到剪贴板")
    }

    private func openResultInBrowser() {
        guard let url = URL(string: resultUrl) else { return }
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        WebVPNConverterView()
    }
}
