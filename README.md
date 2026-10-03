# QuickSleep

原生、离线的助眠应用：Android **Kotlin + Jetpack Compose**，iOS **Swift + SwiftUI**。两套客户端独立实现，共用产品规格、双语文案、音频、字体和设计素材。旧 Flutter 版本保存在 `legacy/`，新工程不依赖 Flutter。

```text
apps/android/       Android 原生工程（Android 8.0+）
apps/ios/           iOS 原生工程（iOS 16+）与 Swift 核心测试
shared/             音频源包、授权、视觉素材、文案、跨平台行为样例
docs/product/       确认的功能与交互要求
docs/architecture/  原生实现与平台差异
scripts/            离线素材恢复、校验、工程生成
legacy/             旧版参考
```

## 功能

- 5/10/15 分钟或 2–60 整数分钟；默认 10 分钟。
- 月下轻语、山间静心、林间晚风；8 秒试听。
- 四轮 4–7–8 呼吸引导，随后自然呼吸；总时长含最后 15 秒淡出，结束后安静停止。
- 后台与锁屏播放、暂停、继续、结束；来电和耳机断开后需手动继续。
- 简体中文 / English；系统、夜间、浅色主题；偏好保存在本机。
- 无账号、统计、广告、网络播放或运行时 TTS。语音与背景均为合成内容，古琴音色为仿古琴合成拨弦。

## 准备资源

需要 Python 3.10+，仅使用标准库，不下载语音模型或音频。

```sh
python scripts/prepare_assets.py
python -m unittest discover -s scripts/tests -v
```

音频和字体的压缩源包提交在 `shared/asset_bundle/`。恢复时验证分片、归档、各文件 SHA256；随后生成 Android 与 iOS 资源。恢复文件与构建输出已忽略。更改文案编辑 `shared/localization/{zh,en}.json`，然后重新准备资源。

## Android

需要 JDK 17、Android SDK（API 35、Build Tools 35.0.0）。用 Android Studio 打开 `apps/android`，或：

```sh
cd apps/android
sh gradlew testDebugUnitTest lintDebug assembleDebug
# Windows: .\gradlew.bat testDebugUnitTest lintDebug assembleDebug
```

Gradle 会自动调用 Python 准备资源；Python 不在 PATH 时加 `-PpythonExecutable=/absolute/path/to/python`。设置 `ANDROID_HOME` 或未提交的 `local.properties` 指向 SDK。

APK：`apps/android/app/build/outputs/apk/debug/app-debug.apk`。这是本地调试签名版本，正式发行需另配签名。

Windows 可选：`python scripts/bootstrap_android.py` 将便携工具安装到本仓库 `.tools/`；随后安装 SDK 组件并按实际工具路径设置 `JAVA_HOME`、`ANDROID_HOME`，不修改系统环境。

## iOS

需要 macOS 与 Xcode 16+。先在仓库根目录准备资源，再打开 `apps/ios/QuickSleep.xcodeproj`，选择 QuickSleep scheme 和模拟器。

```sh
swift test --package-path apps/ios
xcodebuild -project apps/ios/QuickSleep.xcodeproj -scheme QuickSleep \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath apps/ios/build CODE_SIGNING_ALLOWED=NO build
```

新增或删除 Swift 文件后执行 `python scripts/generate_ios_project.py` 更新已提交的工程；不依赖 CocoaPods 或第三方 Swift 包。真机运行在 Xcode 中选择自己的 Team。当前没有发行签名或 App Store 图标交付。

## 实现与验收

开始前在工作线程无损拼接本次完整 WAV，单个原生媒体项目提供全局时长、进度和自动结束；最大时长约需 173 MB 临时磁盘空间。结束、失败和下次启动清理临时文件。UI 只读取媒体进度。

[产品规格](docs/product/native-rewrite.md) · [原生架构](docs/architecture/native.md) · [验证记录](docs/verification.md) · [素材来源](docs/audio-sources.md)

两端的 10 分钟锁屏播放、电话/耳机/蓝牙打断、人工试听及大字布局仍需设备验收；CI 配置存在不代表已运行通过。

专用 Android 模拟器可执行 `python scripts/android_smoke.py --serial emulator-XXXX --adb /path/to/adb`，验证实际两分钟后台播放、暂停与终止，并生成截图。脚本会安装调试 APK、修改测试应用偏好并强制停止测试应用。
