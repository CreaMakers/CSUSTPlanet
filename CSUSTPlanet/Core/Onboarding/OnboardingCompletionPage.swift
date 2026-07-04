//
//  OnboardingCompletionPage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingCompletionPage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                summaryCard
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.green)
                .padding(.top, 16)

            Text("配置完成")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("常用功能已经准备就绪，现在就可以开始使用长理星球了。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("已完成基础引导")
                    .font(.headline)

                Text("后续如需调整账号、宿舍或外观设置，都可以在 App 内继续修改。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }
}
