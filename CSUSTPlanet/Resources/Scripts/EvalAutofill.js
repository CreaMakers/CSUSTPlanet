(() => {
  "use strict";

  const DIALOG_SELECTOR = '#pjcz .el-dialog[role="dialog"]';
  const SCORE_PATTERN = /(\d+(?:\.\d+)?)\s*[（(]\s*分\s*[）)]/g;
  const FULL_TOTAL_CENTS = 10000;
  const MIN_TARGET_CENTS = 1;
  const MAX_TARGET_CENTS = 9999;
  const CENT_EPSILON = 0.000001;

  function isVisible(element) {
    if (!element || !element.isConnected) return false;
    const style = window.getComputedStyle(element);
    return style.display !== "none" && style.visibility !== "hidden" && element.getClientRects().length > 0;
  }

  function getOpenDialog() {
    const dialog = document.querySelector(DIALOG_SELECTOR);
    return isVisible(dialog) ? dialog : null;
  }

  function normalizedText(element) {
    return (element?.innerText || "").replace(/\s+/g, " ").trim();
  }

  function parseMaxima(text) {
    return [...text.matchAll(SCORE_PATTERN)].map((match) => Number(match[1]));
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
    if (!Number.isInteger(targetCents) || targetCents < MIN_TARGET_CENTS || targetCents > MAX_TARGET_CENTS) {
      throw new Error("目标总分必须在 0.01 至 99.99 之间");
    }

    if (!Array.isArray(maximaCents) || maximaCents.length === 0 || maximaCents.some((maximum) => !Number.isInteger(maximum) || maximum <= 0)) {
      throw new Error("题目满分数据无效");
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

    let remainingCents = targetCents - allocations.reduce((total, allocation) => total + allocation.cents, 0);
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
      throw new Error("无法在题目上限内精确分配目标总分");
    }

    return allocations.map((allocation) => allocation.cents);
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
    if (input.type === "hidden" || input.type === "button" || input.type === "submit") return false;
    return isVisible(input);
  }

  function hasSubmitButton(dialog) {
    return [...dialog.querySelectorAll("button")].some((button) => {
      return isVisible(button) && normalizedText(button) === "提交" && !button.disabled;
    });
  }

  function inspectForm(dialog) {
    const editableInputs = [...dialog.querySelectorAll("input")].filter(isEditableInput);
    const scoreFields = editableInputs.map((input, index) => ({ input, index, maximum: getQuestionMaximum(input, dialog) })).filter((field) => Number.isFinite(field.maximum) && field.maximum > 0);
    const hasSubmit = hasSubmitButton(dialog);

    return {
      scoreFields,
      isFillable: scoreFields.length > 0 && hasSubmit,
    };
  }

  function setNativeValue(input, value) {
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value")?.set;
    if (!setter) throw new Error("浏览器不支持 input.value 原生 setter");
    setter.call(input, value);
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
    input.dispatchEvent(new Event("blur", { bubbles: true }));
  }

  function waitForRender() {
    return new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  }

  function readDisplayedTotalCents(dialog) {
    const match = normalizedText(dialog).match(/总得分：\s*(\d+(?:\.\d+)?)/);
    return match ? toCents(Number(match[1])) : null;
  }

  async function fillCurrentForm(targetCents) {
    if (!Number.isInteger(targetCents) || targetCents < MIN_TARGET_CENTS || targetCents > MAX_TARGET_CENTS) {
      const reason = "目标总分必须在 0.01 至 99.99 之间，且最多保留两位小数。";
      return { success: false, message: reason };
    }

    const dialog = getOpenDialog();
    if (!dialog) {
      const reason = "当前没有打开的评教弹窗，请重新打开后再试。";
      return { success: false, message: reason };
    }

    const form = inspectForm(dialog);

    if (!form.isFillable) {
      const reason = "当前弹窗不是可填写的未评价问卷，已跳过。";
      return { success: false, message: reason };
    }

    const maximaCents = form.scoreFields.map((field) => toCents(field.maximum));
    if (maximaCents.some((maximum) => !Number.isInteger(maximum) || maximum <= 0)) {
      const reason = "识别到无法按分币表示的题目满分；为避免填错，未执行填写。";
      return { success: false, message: reason };
    }

    const totalMaximumCents = maximaCents.reduce((total, maximum) => total + maximum, 0);
    if (totalMaximumCents !== FULL_TOTAL_CENTS) {
      const reason = `识别到题目满分合计为 ${formatCents(totalMaximumCents)}，不是 100.00；为避免填错，未执行填写。`;
      return { success: false, message: reason };
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

      return {
        success: true,
        message: `已填写 ${formatCents(targetCents)} 分。`,
      };
    } catch (error) {
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
    attributeFilter: ["class", "style", "aria-hidden", "readonly", "disabled"],
  });

  window.__CSUST_EVAL_AUTOFILL__ = {
    fill: fillCurrentForm,
  };
  scheduleScan();
})();
