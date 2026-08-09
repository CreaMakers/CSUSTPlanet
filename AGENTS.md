# AGENTS.md

本仓库：CSUSTPlanet（Swift/iOS 应用，含 CSUSTPlanetWidget widget target）。

## 修改前需求确认

- 对本仓库中的任何文件进行修改前，必须读取并遵循 `grilling` skill。
- 执行 `grilling` skill 时必须使用提问工具；如果提问工具不可用，则改用普通文本。
- 在 `grilling` skill 要求的最终确认环节，必须先完整汇总共识，再单独询问用户是否确认。
- 仅当用户在当次请求中明确要求“立即执行并忽略 grilling”时，才可以跳过上述流程。该豁免仅对当次请求有效。

## 编译验证

- 只有用户明确要求时才进行编译验证，默认不跑编译验证。
- 需要编译验证时，必须使用 `csustplanet-build` skill，按其中的固定命令执行，不要自行编写 xcodebuild 命令。

## 代码格式化

- 修改完代码后必须执行 `Scripts/format-swift.sh`，使用仓库 `.swift-format` 配置递归格式化 CSUSTPlanet 与 CSUSTPlanetWidget 目录。
