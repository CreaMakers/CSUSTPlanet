fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios sync_certs

```sh
[bundle exec] fastlane ios sync_certs
```

同步 iOS 证书

### ios update_certs

```sh
[bundle exec] fastlane ios update_certs
```

创建或更新 iOS 证书

### ios release

```sh
[bundle exec] fastlane ios release
```

构建 iOS 正式包并上传到 App Store Connect

----


## Mac

### mac sync_certs

```sh
[bundle exec] fastlane mac sync_certs
```

同步 macOS 证书

### mac update_certs

```sh
[bundle exec] fastlane mac update_certs
```

创建或更新 macOS 证书

### mac release

```sh
[bundle exec] fastlane mac release
```

构建 macOS 正式包并上传到 App Store Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
