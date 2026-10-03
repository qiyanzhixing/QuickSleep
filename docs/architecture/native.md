# 原生客户端架构

两端使用独立平台语言和 UI 框架，共用资源与产品约束。客户端不引用 `legacy`，不依赖 Dart、Flutter 或共享业务运行时。

## 领域逻辑

Kotlin 与 Swift 各有 SessionPlan、SessionConfig、Frame、WaveAssembler。59 种时长均遵循 80 + 60 × (M−2) + 25 + 15 = 60M 秒；共享 `shared/session-vectors.json` 固定关键阶段边界。练习开始后配置不可变。

## 有限音频与并发

WAV 数据是原素材 PCM 的原样复制，不重新混音或合成。解析 RIFF 的 fmt/data 块，验证单声道 PCM16、24kHz，再流式复制选定长度。完整 WAV 的帧数正好等于总时长。工作线程按 64KB 块检查取消，失败移除部分输出。最大 60 分钟临时文件为 172,800,044 字节。

每次开始/结束更新请求身份；迟到的拼接或播放器回调不允许覆盖新请求。试听不覆盖正在加载或进行中的练习。两端每个进程只有一个播放器。

## Android

MediaSessionService 持有 ExoPlayer；Activity 通过 MediaController 操作，不持有播放器。有限文件自然结束时清理文件，发布 complete；外部 Stop 发布 idle，页面随状态更新。Settings 作为独立模态层，不由播放结束强行关闭。

手动 AudioFocusRequest 使用语音 content type、willPauseWhenDucked，任何焦点丢失都暂停。重新获得焦点不执行播放，用户操作才重新请求。ExoPlayer 处理耳机 becoming-noisy；原生服务与 wake lock 支持后台播放。ForwardingPlayer 禁止跳转、切曲、速度和重复设置；系统仅开放播放/暂停/停止。Media3 管理通知和前台服务生命周期；系统可能在长时间暂停后撤销前台资格，此边界需要各系统版本真机测试。

偏好使用单个 JSON、串行后台写入 SharedPreferences，失败在 UI 显示；非法字段单独回退。两种语言都随包交付，关闭 App Bundle 语言拆分。

## iOS

@MainActor PlaybackController 持有 AVPlayer，串行工作队列拼接音频。AVAudioSession playback category、UIBackgroundModes audio 支持后台；MPRemoteCommandCenter 与 MPNowPlayingInfoCenter 只公开本次完整练习。打断开始与旧输出设备消失暂停；打断结束不自动恢复。缺失打断结束通知时，显式用户继续可以尝试重新激活音频会话；自动延续仍受打断标记约束。

音频服务重置后清理当前练习并重建播放器，用户可重新开始。原生状态和媒体时间观察驱动 UI；没有 UI 定时器决定音频结束。偏好存在 UserDefaults；PrivacyInfo.xcprivacy 声明本应用自身偏好用途。

Swift Package 只编译 Foundation 核心逻辑用于单元测试；Xcode 工程直接编译相同 Swift 源文件，不引入跨平台应用框架。

## 资源

Python 标准库验证并恢复共享素材，生成双语 Android strings 和 iOS Localizable.strings，复制资源与授权信息。字体保留原字节；其内部 PostScript 名为 NotoSansSC-Thin、NotoSerifSC-ExtraLight，尽管源文件为静态实例化的常规字重。iOS 依照内部名称使用字体，避免回退到系统字体；Medium 与普通 Sans 内部名重复，因此不同时注册 Medium。

## 平台参考

- [Android 官方：后台 MediaSessionService](https://developer.android.com/media/media3/session/background-playback)
- [Android 官方：音频焦点](https://developer.android.com/media/optimize/audio-focus)
- [Apple 官方：音频打断](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HandlingAudioInterruptions/HandlingAudioInterruptions.html)
- [Apple 官方：远程播放器命令](https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter)
