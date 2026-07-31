<img src="CSUSTPlanet/Resources/Assets.xcassets/MinimalLogo.imageset/logo_minimal.png" alt="云岭星球" height="64">

# 云岭星球

云岭星球是为大学生打造的校园服务助手，让您的校园生活更便捷高效。通过本应用，您可以随时查询课表、考试成绩和考试安排，实时掌握宿舍电量情况并接收低电量提醒，快速查看课程作业和作业截止日期

云岭星球的校园网络库由[CSUSTKit](https://github.com/zHElEARN/CSUSTKit)提供支持

支持iOS及iPadOS最低17.0版本，macOS最低14.0版本

## 安装

- 通过[App Store](https://apps.apple.com/cn/app/id6748840801)下载安装
- 通过[TestFlight](https://testflight.apple.com/join/xMbzN8aU)加入测试

## 构建

> [!IMPORTANT]
> **构建要求**：由于云岭星球集成了一些特定的 **App Capabilities**，构建本项目需要具备 **Apple Developer Program** 会员资格。使用免费开发者账号可能导致签名失败或无法正常编译

### 步骤

1. 克隆项目

   ```bash
   git clone https://github.com/zHElEARN/CSUSTPlanet.git
   cd CSUSTPlanet
   ```

2. 项目配置

   云岭星球使用了 `.xcconfig` 文件和环境变量来管理构建配置和敏感信息。在构建前，你需要完成以下两个配置文件的设置：
   - 构建配置 (User.xcconfig)

     复制构建配置模板文件，并填入你的开发者团队信息：

     ```bash
     cp Configs/User.xcconfig.template Configs/User.xcconfig
     ```

   - 环境变量 (.env)

     复制环境变量模板，用于 Fastlane 的签名管理，在 `.env` 文件中填入相应的 Apple ID 和密钥信息：

     ```bash
     cp .env.template .env
     ```

3. 安装依赖

   本项目使用 Bundler 管理 Ruby 依赖（包括 Fastlane）

   ```bash
   gem install bundler
   ```

   安装项目所需的 Ruby gems并安装 iOS 依赖库

   ```bash
   bundle install
   bundle exec fastlane ios sync_certs
   bundle exec fastlane mac sync_certs
   ```

   安装用于构建开源许可列表的 LicensePlist

   ```base
   brew install licenseplist
   ```

4. 运行项目

   使用 Xcode 打开项目文件 `CSUSTPlanet.xcodeproj`，即可构建并运行项目

## 许可证

本项目采用 **MIT License**。

这意味着：

- 您可以自由地商业化使用、复制、修改和分发本项目的源代码及其副本。
- 您只需在分发时保留原作者的版权声明和许可声明即可。
- 您可以将本项目代码集成到您的闭源或商业项目中，且无需公开您自己的源代码。
- 作者不对使用本项目产生的任何后果承担法律责任。

详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎并鼓励大家为 **云岭星球** 做出贡献，您可以 Fork 项目，进行修改并提交 Pull Request。

如果您在使用过程中遇到问题，或对 **云岭星球** 有任何建议，也欢迎提交 Issue 来告知我们！

---

_免责声明: 本项目仅供学习与技术研究使用，请勿用于任何非法用途。在使用过程中请遵守学校相关网络安全规定。_
