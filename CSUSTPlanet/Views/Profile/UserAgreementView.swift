//
//  UserAgreementView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import MarkdownUI
import SwiftUI

let userAgreementMarkdown = """
## 1. 协议确认

在使用"长理星球"iOS应用（以下简称"本应用"）前，请您仔细阅读本用户协议。当您点击"同意"按钮时，即表示您已阅读、理解并同意接受本协议的全部内容。若您不同意本协议的任何条款，请立即退出并停止使用本应用。

## 2. 数据隐私与安全

2.1 **本应用采用客户端直接请求模式，所有与学校系统的交互（包括但不限于教务系统、网络课程中心等）均由您的设备直接向学校服务器发起请求，不会经过任何第三方服务器。**

2.2 **您的学校账号密码仅会加密存储在您的设备本地，本应用不会以任何形式收集、存储或上传您的账号凭证至任何云端服务器。**

2.3 除下述第3条所述情况外，本应用所有功能均在您的设备本地完成数据处理，开发者无法获取您的任何个人信息或使用数据。

## 3. 定时电量查询特别说明

3.1 当您使用"宿舍电量定时查询"功能时，为提供推送服务，我们会在云端服务器存储以下必要信息：
- 设备推送令牌（用于向您的设备发送通知）
- 宿舍信息（仅包含楼栋和房间号）
- 学号（仅用于防滥用目的，不关联其他信息）

3.2 上述数据的存储遵循"最少数据原则"，且仅在您首次设置定时查询功能并明确同意后才会进行存储。

3.3 您可以在应用设置中随时关闭定时查询功能，关闭后相关数据将从服务器删除。

## 4. 免责声明

4.1 **本应用为长沙理工大学学生个人开发项目，非学校官方应用。使用过程中遇到的任何问题请直接联系开发者，切勿向学校相关部门反馈。**

4.2 开发者不对因使用本应用导致的任何直接或间接损失承担责任，包括但不限于：
- 因学校系统变更导致的功能异常
- 因设备或网络问题导致的数据获取失败
- 因不可抗力导致的服务中断

4.3 **您理解并同意，使用本应用查询的各类数据（成绩、课表等）仅供参考，请以学校官方系统数据为准。**

## 5. 协议修改与更新

5.1 开发者保留随时修改本协议条款的权利，修改后的协议将在应用内公布后立即生效。

5.2 若您继续使用本应用，即视为您已接受修改后的协议。

## 6. 联系方式

如有任何关于本协议的疑问，请联系：

- 开发者邮箱：developer@zhelearn.com
- QQ反馈群：[125010161](mqqapi://card/show_pslcard?src_type=internal&version=1&uin=125010161&key=&card_type=group&source=external)

最后更新日期：2025年7月19日
"""

struct UserAgreementView: View {
    @EnvironmentObject var globalVars: GlobalVars

    var body: some View {
        Form {
            Markdown(userAgreementMarkdown)
                .markdownTextStyle(\.strong) {
                    ForegroundColor(.primary)
                    BackgroundColor(.yellow.opacity(0.3))
                    FontWeight(.bold)
                }

            Section {
                Button(action: {
                    globalVars.isUserAgreementAccepted = true
                }) {
                    Text("同意并继续使用")
                }
                .tint(.blue)
                Button(action: {
                    globalVars.isUserAgreementAccepted = false
                    exit(0)
                }) {
                    Text("不同意并退出")
                }
                .tint(.red)
            }
        }

        .background(Color(.systemBackground))
        .navigationTitle("用户协议")
    }
}

#Preview {
    NavigationStack {
        UserAgreementView()
            .environmentObject(GlobalVars.shared)
    }
}
