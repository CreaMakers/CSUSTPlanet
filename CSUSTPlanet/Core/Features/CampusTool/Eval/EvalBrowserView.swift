//
//  EvalBrowserView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/7/17.
//

import CSUSTKit
import SwiftUI
import WebKit

struct EvalBrowserView: PlatformViewRepresentable {
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
