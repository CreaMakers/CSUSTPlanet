# AGENTS.md

本仓库：CSUSTPlanet（Swift/iOS 应用，含 CSUSTPlanetWidget widget target）。

## 编译验证

- 只有用户明确要求时才进行编译验证，默认不跑编译验证。
- 需要编译验证时，必须使用 `csustplanet-build` skill，按其中的固定命令执行，不要自行编写 xcodebuild 命令。

## 代码格式化

- 修改完代码后必须执行 `Scripts/format-swift.sh`，使用仓库 `.swift-format` 配置递归格式化 CSUSTPlanet 与 CSUSTPlanetWidget 目录。
