//
//  AboutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

let aboutMarkdown = """
## 开发者介绍

我是长理星球iOS端的开发者Zhe_Learn，这款应用是我在学习SwiftUI过程中的实践项目。项目完全开源，您可以在GitHub上查看源代码：  
[https://github.com/zHElEARN/CSUSTPlanet](https://github.com/zHElEARN/CSUSTPlanet)

我所属的团队CreaMakers是一个充满活力的技术组织。CreaMaker是由长沙理工大学计算机学院的学生自主创建的组织，旨在通过创新项目和实践活动，激发人的创造力和技术动手能力。在这个组织中，我们不仅会进行技术学习，还会开发有趣且实用的项目，致力于将创意转化为实际的产品和服务。我们的成员热衷于通过技术与创新解决问题，共同成长。

## 开发初衷

开发长理星球iOS端的初衷是为了让同学们能够更加便捷地使用学校的教务系统和网络课程中心。当前版本已经实现了以下功能：

- 教务系统方面：提供方便的成绩查询、考试安排查看以及课表查询服务
- 网络课程中心：提供课程列表查看功能（注：暑假期间学校会关闭外网访问）
- 其他实用功能：宿舍电量查询和定时通知、校园地图导航、校历查看，以及快速进入四六级/普通话查询网站的快捷入口

特别说明的是，目前除了电量定时查询功能外，其他所有功能都在客户端本地运行，开发者不会获取任何用户信息。电量查询功能仅会在服务器保存推送必要的客户端token、宿舍信息和防止滥用的学号，不会存储其他任何隐私数据。后端代码也已开源：[https://github.com/zHElEARN/CSUSTPlanetBackend](https://github.com/zHElEARN/CSUSTPlanetBackend)

未来版本将会继续完善功能，包括开发实用的小组件、未做作业提醒等，持续提升用户体验。

## 特别致谢

在开发过程中，我要特别感谢以下个人和团队的支持与帮助：

BobH开发的i乐学助手为长理星球iOS端提供了部分功能与设计灵感，他的GitHub主页是[https://github.com/BobH233](https://github.com/BobH233)。长沙理工大学拓扑实验室的同学们给了我很多技术上的启发，让我遇到了许多编程高手。同时也要感谢CreaMakers团队的所有成员，在这个充满创造力的团队中，我获得了许多成长与进步。

## 联系我们

如果您有任何反馈、建议，或者有意参与项目开发，欢迎通过以下方式联系我：  
邮箱：[developer@zhelearn.com](mailto:developer@zhelearn.com)

感谢您使用长理星球iOS端，我们将持续改进，为您提供更好的服务体验。
"""

struct AboutView: View {
    var body: some View {
        Form {
            Markdown(aboutMarkdown)

            Section("应用信息") {
                HStack {
                    Text("版本号")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知版本")
                }
                HStack {
                    Text("构建号")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建")
                }
                HStack {
                    Text("运行环境")
                    Spacer()
                    switch AppEnvironmentHelper.currentEnvironment() {
                    case .debug:
                        Text("Debug")
                    case .appStore:
                        Text("App Store")
                    case .testFlight:
                        Text("TestFlight")
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("关于")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
