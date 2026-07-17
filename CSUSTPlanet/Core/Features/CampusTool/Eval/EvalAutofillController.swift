//
//  EvalAutofillController.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/7/17.
//

import SwiftUI
import WebKit

@MainActor
@Observable
final class EvalAutofillController {
    var isAvailable = false
    var isFilling = false
    var isCustomScoreSheetPresented = false
    var customScoreText = "99.99"
    var successToast: ToastState = .successTitle
    var alertMessage: String?

    @ObservationIgnored weak var webView: WKWebView?

    var customTargetCents: Int? {
        Self.parseTargetCents(customScoreText)
    }

    func updateAvailability(_ isAvailable: Bool) {
        self.isAvailable = isAvailable

        if !isAvailable && !isFilling {
            isCustomScoreSheetPresented = false
        }
    }

    func presentCustomScoreSheet() {
        guard isAvailable, !isFilling else { return }
        customScoreText = "99.99"
        alertMessage = nil
        isCustomScoreSheetPresented = true
    }

    func dismissCustomScoreSheet() {
        guard !isFilling else { return }
        isCustomScoreSheetPresented = false
    }

    func fillCustomScore() async {
        guard !isFilling, let targetCents = customTargetCents else { return }

        guard let webView else {
            alertMessage = "评教页面尚未准备完成，请稍后重试。"
            return
        }

        isFilling = true
        defer { isFilling = false }

        do {
            let rawResult = try await webView.callAsyncJavaScript(
                "return await window.__CSUST_EVAL_AUTOFILL__?.fill(targetCents);",
                arguments: ["targetCents": targetCents],
                in: nil,
                contentWorld: .page
            )

            guard let result = rawResult as? [String: Any],
                let success = result["success"] as? Bool,
                let message = result["message"] as? String
            else {
                alertMessage = "页面未返回有效的填写结果，请重新打开评教弹窗后重试。"
                return
            }

            if success {
                successToast.show(message: message)
                isCustomScoreSheetPresented = false
            } else {
                alertMessage = message
            }
        } catch {
            alertMessage = "调用页面填写功能失败：\(error.localizedDescription)"
        }
    }

    private static func parseTargetCents(_ text: String) -> Int? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedText.split(separator: ".", omittingEmptySubsequences: false)

        guard (1...2).contains(components.count),
            let wholePart = components.first,
            !wholePart.isEmpty,
            wholePart.allSatisfy({ $0.isNumber }),
            let wholeValue = Int(wholePart),
            wholeValue <= 99
        else {
            return nil
        }

        var fractionValue = 0
        if components.count == 2 {
            let fractionPart = components[1]
            guard !fractionPart.isEmpty,
                fractionPart.count <= 2,
                fractionPart.allSatisfy({ $0.isNumber }),
                let parsedFraction = Int(fractionPart)
            else {
                return nil
            }

            fractionValue = fractionPart.count == 1 ? parsedFraction * 10 : parsedFraction
        }

        let targetCents = wholeValue * 100 + fractionValue
        return (1...9_999).contains(targetCents) ? targetCents : nil
    }
}
