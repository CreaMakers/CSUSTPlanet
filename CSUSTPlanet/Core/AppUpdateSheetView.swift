//
//  AppUpdateSheetView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import OSLog
import SwiftUI

struct AppUpdateSheetView: View {
    @Bindable var globalManager = GlobalManager.shared
    @Environment(\.openURL) private var openURL

    private var latestVersion: PlanetConfigService.AppVersion? {
        globalManager.latestAppVersion
    }

    private var isForceUpdate: Bool {
        globalManager.isForceUpdateRequired
    }

    private var releaseNotes: String {
        if let latestVersion = latestVersion {
            return latestVersion.releaseNotes.isEmpty ? "暂无更新说明" : latestVersion.releaseNotes
        }
        return "暂无更新说明"
    }

    private var currentVersionName: String {
        AppVersionUtil.currentVersionName ?? "未知版本"
    }

    private var downloadURLText: String {
        latestVersion?.downloadUrl.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func handleUpdate() {
        guard let latestVersion else { return }
        guard let url = URL(string: latestVersion.downloadUrl) else { return }

        openURL(url)

        if !isForceUpdate {
            globalManager.dismissAppUpdateSheet()
        }
    }

    private func handleLater() {
        globalManager.ignoreCurrentAppUpdate()
    }

    var body: some View {
        NavigationStack {
            Group {
                if let latestVersion {
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text(isForceUpdate ? "当前版本过低，需要更新后才能继续使用" : "发现新版本")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("\(currentVersionName)  →  \(latestVersion.versionName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("更新说明")
                                .font(.headline)

                            ScrollView {
                                Text(releaseNotes)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 24)

                        if URL(string: downloadURLText) == nil {
                            Text("下载地址异常：\(downloadURLText)")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.top, 8)
                        }

                        Button(action: handleUpdate) {
                            Text("立即更新")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    }
                } else {
                    ContentUnavailableView("暂无版本信息", systemImage: "square.and.arrow.down")
                }
            }
            .navigationTitle("版本更新")
            .inlineToolbarTitle()
            .toolbar {
                if !isForceUpdate {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("忽略本次", action: handleLater)
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
        .interactiveDismissDisabled(isForceUpdate)
    }
}
