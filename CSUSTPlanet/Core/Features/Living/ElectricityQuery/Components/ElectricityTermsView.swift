//
//  ElectricityTermsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import SwiftUI

struct ElectricityTermsView: View {
    @Binding var isPresented: Bool
    @State var isAgreed: Bool = false
    
    var onAgree: () -> Void
    
    struct TermItem: View {
        let title: String
        let content: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("长理星球电量查询服务条例")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10)
                        
                    Text("感谢您使用长理星球App的定时电量查询功能。为了提供更好的服务，我们需要您同意以下条款：")
                        
                    VStack(alignment: .leading, spacing: 12) {
                        TermItem(
                            title: "信息收集",
                            content: "我们需要收集您的手机设备信息用于推送通知，收集您的学号信息用于防止服务滥用，收集您的宿舍信息用于电量查询。这些信息将安全存储在服务器上。"
                        )
                            
                        TermItem(
                            title: "数据使用",
                            content: "您的信息仅用于电量查询服务，不会用于其他用途或分享给第三方。"
                        )
                            
                        TermItem(
                            title: "服务条款",
                            content: "您理解并同意，此服务依赖于学校电量查询系统的稳定性，我们无法保证100%的查询成功率。"
                        )
                    }
                        
                    Toggle("我已阅读并同意以上条款", isOn: $isAgreed)
                        .padding(.vertical)
                        
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("服务条款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                    
                ToolbarItem(placement: .confirmationAction) {
                    Button("同意") {
                        isPresented = false
                        MMKVManager.shared.isElectricityTermAccepted = true
                        onAgree()
                    }
                    .disabled(!isAgreed)
                    .foregroundColor(isAgreed ? .blue : .gray)
                }
            }
        }
    }
}

#Preview {
    ElectricityTermsView(isPresented: .constant(true), onAgree: {})
}
