---
name: csustplanet-build
description: 使用固定 xcodebuild 流程验证云岭星球项目代码是否存在编译期错误。
disable-model-invocation: true
---

# 云岭星球编译

使用此 Skill 时，在项目根目录下直接运行固定编译命令，用于确认代码是否存在编译期错误。

## 编译命令

运行命令时直接申请沙箱外权限；不要先在沙箱内试跑。输出必须通过 `xcbeautify` 过滤以减少日志噪音和上下文占用。

```bash
set -o pipefail
xcodebuild \
  -project CSUSTPlanet.xcodeproj \
  -scheme CSUSTPlanet \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  build 2>&1 | xcbeautify
```

默认使用 `generic/platform=iOS`，这是日常验证首选 destination。

如果当前任务需要验证 macOS 构建，仅将 destination 改为 `generic/platform=macOS`，其他参数保持不变。

## 项目信息

- Project：`CSUSTPlanet.xcodeproj`
- 主 scheme：`CSUSTPlanet`
- Widget scheme：`CSUSTPlanetWidgetExtension`
- 主 `CSUSTPlanet` scheme 已经会构建 widget extension 依赖。
- 默认产物路径：`.build/DerivedData/Build/Products/Debug-iphoneos/CSUSTPlanet.app`
