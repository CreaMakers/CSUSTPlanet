//
//  AboutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

struct AboutView: View {
    @State private var viewModel = AboutViewModel()

    var body: some View {
        Form {
            Section {
                HStack {
                    AboutAppIconView()
                        .frame(width: 158, height: 158)

                    VStack {
                        Text("长理星球")
                            .font(.title2.weight(.semibold))

                        Group {
                            Text("\(viewModel.appVersion)（\(viewModel.buildNumber))")
                            Text(viewModel.environment)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if let aboutMarkdown = viewModel.aboutMarkdown {
                Markdown(aboutMarkdown)
            } else {
                Text("无法加载关于信息")
            }

            Section("更多信息") {
                NavigationLink(value: AppRoute.profile(.about(.openSourceLicenses(.main)))) {
                    Text("开源许可")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("关于")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
