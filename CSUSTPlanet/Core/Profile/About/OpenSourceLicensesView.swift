//
//  OpenSourceLicensesView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/4/3.
//

import SwiftUI

@MainActor
@Observable
final class OpenSourceLicensesViewModel {
    var licenses: [OpenSourceLicense] = []
    var errorMessage: String?

    init() {
        loadLicenses()
    }

    func loadLicenses() {
        do {
            licenses = try LicensePlistLoader.loadLicenses()
            errorMessage = nil
        } catch {
            licenses = []
            errorMessage = error.localizedDescription
        }
    }
}

struct OpenSourceLicensesView: View {
    @State private var viewModel = OpenSourceLicensesViewModel()

    var body: some View {
        Form {
            Section {
                FormRow(label: "开源项目数量", value: "\(viewModel.licenses.count)")
            } header: {
                Text("说明")
            } footer: {
                Text("以下是云岭星球中使用的开源项目及其许可证信息。点击每个项目可以查看详细的许可证内容。")
            }

            if let errorMessage = viewModel.errorMessage {
                Section("加载失败") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            } else {
                Section("许可证列表") {
                    if viewModel.licenses.isEmpty {
                        Text("未找到开源许可证信息")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.licenses) { license in
                            NavigationLink(value: AppRoute.profile(.about(.openSourceLicenses(.detail(license))))) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(license.title)

                                    if let subtitle = license.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(license.body == nil ? .red : .secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("开源许可")
    }
}

struct OpenSourceLicenseDetailView: View {
    let license: OpenSourceLicense

    var body: some View {
        Form {
            Section("项目信息") {
                FormRow(label: "项目名称", value: license.title)

                if let licenseName = license.licenseName, licenseName.isKnownLicenseName {
                    FormRow(label: "协议类型", value: licenseName)
                }
            }

            Section("许可证全文") {
                if let body = license.body {
                    Text(verbatim: body)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                } else {
                    Text(license.errorMessage ?? "无法加载许可证内容")
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(license.title)
    }
}
