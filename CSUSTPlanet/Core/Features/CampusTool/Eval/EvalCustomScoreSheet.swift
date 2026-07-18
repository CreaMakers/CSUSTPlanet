//
//  EvalCustomScoreSheet.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/7/17.
//

import SwiftUI

struct EvalCustomScoreSheet: View {
    @Bindable var controller: EvalAutofillController

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例如 85.50", text: $controller.customScoreText)
                        #if os(iOS)
                    .keyboardType(.decimalPad)
                        #endif
                } header: {
                    Text("目标总分")
                } footer: {
                    VStack(alignment: .leading) {
                        if controller.customTargetCents == nil {
                            Text("请输入 0.01 至 99.99 之间、最多两位小数的数字。")
                                .foregroundStyle(.red)
                        } else {
                            Text("允许范围为 0.01 至 99.99，最多两位小数。")
                        }

                        Text("系统会按每道题的满分权重分配分值。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("填写自定义分数")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        controller.dismissCustomScoreSheet()
                    }
                    .disabled(controller.isFilling)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(asyncAction: controller.fillCustomScore) {
                        if controller.isFilling {
                            ProgressView().smallControlSizeOnMac()
                        } else {
                            Text("填写")
                        }
                    }
                    .disabled(controller.customTargetCents == nil || controller.isFilling)
                }
            }
        }
        .interactiveDismissDisabled(controller.isFilling)
        .alert(
            "一键填写失败",
            isPresented: Binding(
                get: { controller.alertMessage != nil },
                set: { if !$0 { controller.alertMessage = nil } }
            ), presenting: controller.alertMessage
        ) { _ in
            Button("确定", role: .cancel) {
                controller.alertMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
}
