//
//  WebVPNConverterView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/6/17.
//

import CSUSTKit
import SwiftUI
import WebKit

struct EvalView: View {
    @State private var webViewController = WebViewController()
    @State private var autofillController = EvalAutofillController()
    @State private var isAutofillActionsPresented = false

    private var isShowingAutofillAlert: Binding<Bool> {
        Binding(
            get: {
                autofillController.alertMessage != nil && !autofillController.isCustomScoreSheetPresented
            },
            set: { isPresented in
                if !isPresented {
                    autofillController.dismissAlert()
                }
            }
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            EvalBrowserView(
                controller: webViewController,
                autofillController: autofillController
            )

            if autofillController.isAvailable {
                Button {
                    isAutofillActionsPresented = true
                } label: {
                    HStack(spacing: 8) {
                        if autofillController.isFilling {
                            ProgressView()
                        } else {
                            Image(systemName: "wand.and.stars")
                        }

                        Text("辅助填写")
                    }
                }
                .controlSize(.large)
                .apply { view in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        view.buttonStyle(.glassProminent)
                    } else {
                        view.buttonStyle(.borderedProminent)
                    }
                }
                .disabled(autofillController.isFilling)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .confirmationDialog("辅助填写", isPresented: $isAutofillActionsPresented, titleVisibility: .visible) {
                    Button(asyncAction: autofillController.fill99_99) {
                        Label("填写 99.99 分", systemImage: "wand.and.stars")
                    }

                    Button {
                        autofillController.presentCustomScoreSheet()
                    } label: {
                        Label("填写自定义分数", systemImage: "number")
                    }

                    Button("取消", role: .cancel) {}
                }
            }
        }
        .animation(.default, value: autofillController.isAvailable)
        .onChange(of: autofillController.isAvailable) { _, isAvailable in
            if !isAvailable {
                isAutofillActionsPresented = false
            }
        }
        .alert("一键填写失败", isPresented: isShowingAutofillAlert, presenting: autofillController.alertMessage) { _ in
            Button("确定", role: .cancel) {
                autofillController.dismissAlert()
            }
        } message: { message in
            Text(message)
        }
        .sheet(isPresented: $autofillController.isCustomScoreSheetPresented) {
            #if os(iOS)
            EvalCustomScoreSheet(controller: autofillController)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            #else
            EvalCustomScoreSheet(controller: autofillController)
                .frame(width: 420, height: 280)
            #endif
        }
        .successToast($autofillController.successToast)
        .inlineToolbarTitle()
        .navigationTitle("评教系统")
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}

@MainActor
@Observable
private final class EvalAutofillController {
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

    var customScoreValidationMessage: String? {
        customTargetCents == nil
            ? "请输入 0.01 至 99.99 之间、最多两位小数的数字。"
            : nil
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

    func fill99_99() async {
        _ = await fill(targetCents: 9_999)
    }

    func fillCustomScore() async {
        guard let targetCents = customTargetCents else { return }

        if await fill(targetCents: targetCents) {
            isCustomScoreSheetPresented = false
        }
    }

    @discardableResult
    private func fill(targetCents: Int) async -> Bool {
        guard !isFilling, (1...9_999).contains(targetCents) else { return false }

        guard let webView else {
            alertMessage = "评教页面尚未准备完成，请稍后重试。"
            return false
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
                return false
            }

            if success {
                successToast.show(message: message)
                return true
            } else {
                alertMessage = message
                return false
            }
        } catch {
            alertMessage = "调用页面填写功能失败：\(error.localizedDescription)"
            return false
        }
    }

    func dismissAlert() {
        alertMessage = nil
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

private struct EvalCustomScoreSheet: View {
    @Bindable var controller: EvalAutofillController

    private var isShowingAutofillAlert: Binding<Bool> {
        Binding(
            get: { controller.alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    controller.dismissAlert()
                }
            }
        )
    }

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
                    if let validationMessage = controller.customScoreValidationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("允许范围为 0.01 至 99.99，最多两位小数。")
                    }
                }

                Section {
                    Text("系统会按每道题的满分权重分配分值。")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("填写自定义分数")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
                            ProgressView()
                                .controlSize(.small)
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
            isPresented: isShowingAutofillAlert,
            presenting: controller.alertMessage
        ) { _ in
            Button("确定", role: .cancel) {
                controller.dismissAlert()
            }
        } message: { message in
            Text(message)
        }
    }
}

private struct EvalBrowserView: PlatformViewRepresentable {
    static let factory = URLFactory(mode: AuthManager.shared.mode)
    private static let autofillStateMessageName = "evaluationAutofillState"

    private static let evaluationAutofillSource = #"""
        (() => {
          'use strict';

          const LOG_PREFIX = '[CSUST AutoFill]';
          const DIALOG_SELECTOR = '#pjcz .el-dialog[role="dialog"]';
          const SCORE_PATTERN = /(\d+(?:\.\d+)?)\s*[（(]\s*分\s*[）)]/g;
          const FULL_TOTAL_CENTS = 10000;
          const MIN_TARGET_CENTS = 1;
          const MAX_TARGET_CENTS = 9999;
          const CENT_EPSILON = 0.000001;

          function log(message, details) {
            if (details === undefined) {
              console.info(LOG_PREFIX, message);
            } else {
              console.info(LOG_PREFIX, message, details);
            }
          }

          function warn(message, details) {
            if (details === undefined) {
              console.warn(LOG_PREFIX, message);
            } else {
              console.warn(LOG_PREFIX, message, details);
            }
          }

          function isVisible(element) {
            if (!element || !element.isConnected) return false;
            const style = window.getComputedStyle(element);
            return style.display !== 'none'
              && style.visibility !== 'hidden'
              && element.getClientRects().length > 0;
          }

          function getOpenDialog() {
            const dialog = document.querySelector(DIALOG_SELECTOR);
            return isVisible(dialog) ? dialog : null;
          }

          function normalizedText(element) {
            return (element?.innerText || '').replace(/\s+/g, ' ').trim();
          }

          function parseMaxima(text) {
            return [...text.matchAll(SCORE_PATTERN)].map(match => Number(match[1]));
          }

          function toCents(value) {
            if (!Number.isFinite(value)) return null;

            const scaledValue = value * 100;
            const roundedValue = Math.round(scaledValue);
            return Math.abs(scaledValue - roundedValue) <= CENT_EPSILON ? roundedValue : null;
          }

          function formatCents(cents) {
            return (cents / 100).toFixed(2);
          }

          function allocateScoreCents(maximaCents, targetCents) {
            if (!Number.isInteger(targetCents)
              || targetCents < MIN_TARGET_CENTS
              || targetCents > MAX_TARGET_CENTS) {
              throw new Error('目标总分必须在 0.01 至 99.99 之间');
            }

            if (!Array.isArray(maximaCents)
              || maximaCents.length === 0
              || maximaCents.some(maximum => !Number.isInteger(maximum) || maximum <= 0)) {
              throw new Error('题目满分数据无效');
            }

            const totalMaximumCents = maximaCents.reduce((total, maximum) => total + maximum, 0);
            if (totalMaximumCents !== FULL_TOTAL_CENTS) {
              throw new Error(`识别到题目满分合计为 ${formatCents(totalMaximumCents)}，不是 100.00`);
            }

            const allocations = maximaCents.map((maximumCents, index) => {
              const numerator = targetCents * maximumCents;
              return {
                index,
                maximumCents,
                cents: Math.floor(numerator / totalMaximumCents),
                remainder: numerator % totalMaximumCents,
              };
            });

            let remainingCents = targetCents
              - allocations.reduce((total, allocation) => total + allocation.cents, 0);
            const remainderOrder = [...allocations].sort((left, right) => {
              return right.remainder - left.remainder || left.index - right.index;
            });

            for (const allocation of remainderOrder) {
              if (remainingCents === 0) break;
              if (allocation.cents >= allocation.maximumCents) continue;

              allocation.cents += 1;
              remainingCents -= 1;
            }

            if (remainingCents !== 0) {
              throw new Error('无法在题目上限内精确分配目标总分');
            }

            return allocations.map(allocation => allocation.cents);
          }

          function getQuestionMaximum(input, dialog) {
            let container = input.parentElement;

            while (container && container !== dialog.parentElement) {
              const maxima = parseMaxima(normalizedText(container));
              if (maxima.length === 1) return maxima[0];
              if (container === dialog) break;
              container = container.parentElement;
            }

            return null;
          }

          function isEditableInput(input) {
            if (!(input instanceof HTMLInputElement)) return false;
            if (input.disabled || input.readOnly) return false;
            if (input.type === 'hidden' || input.type === 'button' || input.type === 'submit') return false;
            return isVisible(input);
          }

          function hasSubmitButton(dialog) {
            return [...dialog.querySelectorAll('button')].some(button => {
              return isVisible(button) && normalizedText(button) === '提交' && !button.disabled;
            });
          }

          function inspectForm(dialog) {
            const editableInputs = [...dialog.querySelectorAll('input')].filter(isEditableInput);
            const scoreFields = editableInputs
              .map((input, index) => ({ input, index, maximum: getQuestionMaximum(input, dialog) }))
              .filter(field => Number.isFinite(field.maximum) && field.maximum > 0);

            const readOnlyScoreFields = [...dialog.querySelectorAll('input')]
              .filter(input => input instanceof HTMLInputElement
                && isVisible(input)
                && (input.readOnly || input.disabled)
                && input.type !== 'hidden')
              .map((input, index) => ({ input, index, maximum: getQuestionMaximum(input, dialog) }))
              .filter(field => Number.isFinite(field.maximum) && field.maximum > 0);

            const maxima = scoreFields.map(field => field.maximum);
            const totalMaximum = maxima.reduce((total, maximum) => total + maximum, 0);
            const courseHeader = normalizedText(dialog).match(/课程：\s*([^\n]*?)(?:\s+教师：|$)/)?.[1] || '未知课程';

            return {
              courseHeader,
              hasSubmit: hasSubmitButton(dialog),
              editableInputs,
              scoreFields,
              readOnlyScoreFields,
              totalMaximum,
              isFillable: scoreFields.length > 0 && hasSubmitButton(dialog),
              isCompleted: !hasSubmitButton(dialog) && readOnlyScoreFields.length > 0,
            };
          }

          function setNativeValue(input, value) {
            const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
            if (!setter) throw new Error('浏览器不支持 input.value 原生 setter');
            setter.call(input, value);
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            input.dispatchEvent(new Event('blur', { bubbles: true }));
          }

          function waitForRender() {
            return new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
          }

          function readDisplayedTotalCents(dialog) {
            const match = normalizedText(dialog).match(/总得分：\s*(\d+(?:\.\d+)?)/);
            return match ? toCents(Number(match[1])) : null;
          }

          async function fillTarget(dialog, targetCents) {
            const form = inspectForm(dialog);
            log('开始分析问卷', {
              course: form.courseHeader,
              targetScore: formatCents(targetCents),
              editableInputCount: form.editableInputs.length,
              scoreFieldCount: form.scoreFields.length,
              totalMaximum: form.totalMaximum,
            });

            if (!form.isFillable) {
              const reason = '当前弹窗不是可填写的未评价问卷，已跳过。';
              warn(reason, form);
              return { success: false, message: reason };
            }

            const maximaCents = form.scoreFields.map(field => toCents(field.maximum));
            if (maximaCents.some(maximum => !Number.isInteger(maximum) || maximum <= 0)) {
              const reason = '识别到无法按分币表示的题目满分；为避免填错，未执行填写。';
              warn(reason, form.scoreFields.map(field => field.maximum));
              return { success: false, message: reason };
            }

            const totalMaximumCents = maximaCents.reduce((total, maximum) => total + maximum, 0);
            if (totalMaximumCents !== FULL_TOTAL_CENTS) {
              const reason = `识别到题目满分合计为 ${formatCents(totalMaximumCents)}，不是 100.00；为避免填错，未执行填写。`;
              warn(reason, maximaCents);
              return { success: false, message: reason };
            }

            const existingValueCount = form.scoreFields.filter(({ input }) => input.value.trim() !== '').length;
            if (existingValueCount > 0) {
              log(`将直接覆盖已有的 ${existingValueCount} 个评分。`);
            }

            try {
              const valuesCents = allocateScoreCents(maximaCents, targetCents);
              const values = valuesCents.map(formatCents);

              form.scoreFields.forEach(({ input }, index) => setNativeValue(input, values[index]));
              await waitForRender();

              const valueCheck = form.scoreFields.every(({ input }, index) => {
                return toCents(Number(input.value)) === valuesCents[index];
              });
              const expectedTotalCents = valuesCents.reduce((total, value) => total + value, 0);
              const displayedTotalCents = readDisplayedTotalCents(dialog);

              if (!valueCheck || expectedTotalCents !== targetCents) {
                throw new Error(`填写后校验失败：expectedTotalCents=${expectedTotalCents}, valueCheck=${valueCheck}`);
              }

              if (displayedTotalCents !== null && displayedTotalCents !== targetCents) {
                throw new Error(`页面总分为 ${formatCents(displayedTotalCents)}，预期为 ${formatCents(targetCents)}`);
              }

              log('填写完成，未提交', {
                course: form.courseHeader,
                targetScore: formatCents(targetCents),
                values,
                displayedTotal: displayedTotalCents === null ? null : formatCents(displayedTotalCents),
              });
              return {
                success: true,
                message: `已填写 ${formatCents(targetCents)} 分。`,
              };
            } catch (error) {
              console.error(LOG_PREFIX, '填写或校验失败；未执行提交。', error);
              return { success: false, message: `填写失败：${error.message}` };
            }
          }

          let lastPublishedAvailability = null;

          function publishAvailability(isAvailable) {
            const handler = window.webkit?.messageHandlers?.evaluationAutofillState;
            if (!handler || isAvailable === lastPublishedAvailability) return;

            lastPublishedAvailability = isAvailable;
            handler.postMessage({ isAvailable });
          }

          function scan() {
            const dialog = getOpenDialog();
            const form = dialog ? inspectForm(dialog) : null;
            publishAvailability(form?.isFillable === true);
          }

          async function fillCurrentForm(targetCents) {
            if (!Number.isInteger(targetCents)
              || targetCents < MIN_TARGET_CENTS
              || targetCents > MAX_TARGET_CENTS) {
              const reason = '目标总分必须在 0.01 至 99.99 之间，且最多保留两位小数。';
              warn(reason, targetCents);
              return { success: false, message: reason };
            }

            const dialog = getOpenDialog();
            if (!dialog) {
              const reason = '当前没有打开的评教弹窗，请重新打开后再试。';
              warn(reason);
              return { success: false, message: reason };
            }

            return fillTarget(dialog, targetCents);
          }

          let scanScheduled = false;
          function scheduleScan() {
            if (scanScheduled) return;
            scanScheduled = true;
            requestAnimationFrame(() => {
              scanScheduled = false;
              scan();
            });
          }

          const observer = new MutationObserver(scheduleScan);
          observer.observe(document.documentElement, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['class', 'style', 'aria-hidden', 'readonly', 'disabled'],
          });

          window.__CSUST_EVAL_AUTOFILL__ = {
            inspectForm,
            scan,
            fill: fillCurrentForm,
            allocateScoreCents,
          };
          log('脚本已启动：检测可填写问卷并向 App 发布状态。');
          scheduleScan();
        })();
        """#

    let controller: WebViewController
    let autofillController: EvalAutofillController

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var controller: WebViewController?
        weak var autofillController: EvalAutofillController?

        init(
            controller: WebViewController,
            autofillController: EvalAutofillController
        ) {
            self.controller = controller
            self.autofillController = autofillController
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            controller?.syncState()
            autofillController?.updateAvailability(false)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            controller?.syncState()
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == EvalBrowserView.autofillStateMessageName,
                message.frameInfo.isMainFrame,
                let body = message.body as? [String: Any],
                let isAvailable = body["isAvailable"] as? Bool
            else {
                return
            }

            autofillController?.updateAvailability(isAvailable)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            controller: controller,
            autofillController: autofillController
        )
    }

    private func makeWebView(coordinator: Coordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = dataStore
        configuration.userContentController.add(
            coordinator,
            name: Self.autofillStateMessageName
        )

        let viewportSource = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=1280, initial-scale=0.3, maximum-scale=5.0, minimum-scale=0.1';
            document.head.appendChild(meta);
            """

        configuration.userContentController.addUserScript(
            WKUserScript(
                source: viewportSource,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: Self.evaluationAutofillSource,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)

        webView.navigationDelegate = coordinator

        controller.webView = webView
        controller.syncState()
        autofillController.webView = webView
        autofillController.updateAvailability(false)

        let cookies = CookieHelper.shared.session.sessionConfiguration.httpCookieStorage?.cookies ?? []
        let cookieStore = dataStore.httpCookieStore
        let group = DispatchGroup()

        for cookie in cookies {
            group.enter()
            cookieStore.setCookie(cookie) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            webView.load(URLRequest(url: URL(string: Self.factory.make(.eval, "/api/manage/cas/toUrl?type=pc"))!))
        }

        return webView
    }

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    #endif

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
    #endif
}
