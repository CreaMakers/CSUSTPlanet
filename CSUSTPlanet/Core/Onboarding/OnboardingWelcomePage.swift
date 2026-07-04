//
//  OnboardingWelcomePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingWelcomePage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                featureCard
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("MinimalLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 16)

            Text("欢迎使用长理星球")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("你的校园课程、课表、生活辅助助手")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private var featureCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 16) {
                featureRow(
                    title: "教务数据查询",
                    description: "支持获取并展示个人课表、考试安排及考试成绩数据等。"
                )

                Divider()

                featureRow(
                    title: "宿舍电量查询",
                    description: "查询宿舍剩余电量并计算预计耗尽时间。"
                )

                Divider()

                featureRow(
                    title: "课程作业查询",
                    description: "汇总网络课程平台作业信息，查看所有课程的作业提交和截止信息。"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func featureRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
