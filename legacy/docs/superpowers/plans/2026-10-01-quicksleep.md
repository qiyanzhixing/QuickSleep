# QuickSleep Android iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付可离线使用、支持中英双语的 QuickSleep Android 与 iOS 应用，并把代码及成品音频推送到指定仓库。

**Architecture:** Flutter 共享界面与纯 Dart 会话模型。一个音频服务持有有限原生播放队列，界面和锁屏读取同一实际媒体进度；最终淡出预先写入音频。

**Tech Stack:** Flutter、Dart、just_audio、audio_service、audio_session、shared_preferences、Flutter l10n；Python、NumPy、Kokoro、ffmpeg 用于构建期音频制作。

**Spec:** 已确认的《QuickSleep Android iOS 实现设计草案》。实施时保存为 `docs/superpowers/specs/2026-10-01-quicksleep-design.md`；本计划保存为 `docs/superpowers/plans/2026-10-01-quicksleep.md`。设计于 2026-10-01 获得确认，本计划仍待审阅后执行。

## Global Constraints

- 总时长：5、10、15 分钟和自定义，首次默认 10 分钟
- 自定义时长为 2–60 的整数分钟；非法、空白、小数和越界输入不保存
- 每个呼吸计数间隔为 1 秒；4 轮共 76 秒，随后 4 秒轻声提示恢复自然呼吸
- 总时长包含引导与最后 15 秒淡出；结束后保持安静，不提示、不自动重播
- 暂停期间不消耗剩余时间；来电和耳机断开后必须手动继续
- 试听为 8 秒的本地示例；同一时刻只播放一个，关闭选择页即停止，开始练习前也停止
- 一段已开始的练习固定其语言、模式和时长；设置更改作用于下一次练习
- 全部成品音频随应用安装包提供，首次启动即可断网使用
- 首页只保留时长与声音模式；不恢复轮数选择或独立音量滑杆
- 主题与语言默认跟随系统，可手动覆盖；所有界面、引导和系统播放器信息均提供中文与英语
- 合成语音明确标注；合成拨弦标注为古琴风格，不称真实古琴演奏
- 系统强制结束应用后不自动恢复播放

## Review Focus

1. 快速重复开始、异步音频加载完成顺序颠倒：只能有一个当前会话，过期请求不得重新发声（任务 3）
2. 后台与锁屏跨越片段边界：无需界面定时器仍然正确淡出、停止和报告全局进度（任务 3、5）
3. 字体放大、英语长文字和窄屏：内容可见、可滚动、可点击，无固定高度裁切（任务 4）
4. 损坏设置、缺失素材或解码失败：安全回到可操作状态，不假装正在播放或静默切换语言（任务 1、2、3）
5. 试听被关闭、电话打断、耳机断开：立即暂停或停止，未经点击不得自动恢复（任务 3、4、5）

## Task 1 产出可验证的离线音频与项目基础

**Files:** 创建 `pubspec.yaml`、`pubspec.lock`、`.fvmrc`、`lib/main.dart`、`android/`、`ios/`；更新 `.gitignore`；创建 `tools/audio/generate_assets.py`、`tools/audio/verify_assets.py`、`tools/audio/requirements.txt`、`tools/audio/tests/test_assets.py`、`assets/audio/catalog.json`、`assets/audio/zh/`、`assets/audio/en/`、`assets/audio/beds/`、`assets/licenses/`。

**Interfaces:** `generate_assets.py --output assets/audio` 生成目录与清单；`verify_assets.py assets/audio` 成功退出 0，否则非 0。清单条目字段固定为 `id, path, locale, mode, role, durationMs, sha256, provenance`；mode 为 `moon|mountain|forest`，role 为 `guide|preview|bed|fade`，背景与尾段 locale 为 `shared`。id 为 `locale.mode.role`，例如 `zh.moon.guide`、`shared.moon.bed`。

- [ ] 从基线 `fd589857403951fc664697bf6847330ed12bbd4c` 建立隔离分支 `feat/offline-bilingual-app`。配置官方 Flutter、Android JDK/SDK和音频生成依赖；记录实际成功版本并锁定，不从搜索摘要猜版本。失败时保留日志并处理可恢复错误，未经证实不宣称构建可用。
- [ ] 写 `test_assets.py` 的失败测试：18 个音频条目全部存在；6 个 guide 各 80000ms、6 个 preview 各 8000ms、3 个 bed 各 60000ms、3 个 fade 各 15000ms。每项 provenance 非空；缺失文件、错误校验值、错误时长均导致校验失败。

```python
# test_catalog_has_eighteen_assets
assert len(catalog) == 18
assert sorted(item['durationMs'] for item in catalog) == sorted([80000]*6+[8000]*6+[60000]*3+[15000]*3)
# test_missing_file_fails_validation: 删除测试夹具中的一个文件后
assert verification_process.returncode != 0
```

- [ ] 运行 `python3 -m unittest discover -s tools/audio/tests -v`，确认缺少生成器或素材时测试失败。
- [ ] 实现生成器与校验器：提前合成六组中英引导、六段试听、三段原创背景及三段淡出，共 18 个音频文件。复用正版模型并保存具体授权；生成过程不进入应用运行时。音频统一采样规格，编码后测量时长误差不超过 20ms；峰值低于 −1dBFS，尾段最后 100ms RMS 低于 −60dBFS，连续片段边界跳变低于 −40dBFS。
- [ ] 运行测试及 `python3 tools/audio/verify_assets.py assets/audio`，要求全部通过；完整试听两种语言的三个引导与试听并确认发音、性别风格、计数、无突兀接缝。生成模型不可用或声音不可用时阻止成品交付，不用缺失文件占位。
- [ ] 提交：`git add pubspec.yaml pubspec.lock .fvmrc .gitignore lib/main.dart android ios tools assets docs; git commit -m "build: scaffold mobile app and bundled bilingual audio"`。

## Task 2 完成会话模型 本地设置和语言资源

**Files:** 创建 `lib/session/session_plan.dart`、`lib/audio/audio_catalog.dart`、`lib/settings/preferences.dart`、`lib/l10n/app_zh.arb`、`lib/l10n/app_en.arb`、`l10n.yaml`；测试 `test/session_plan_test.dart`、`test/preferences_test.dart`、`test/localization_test.dart`。

**Interfaces:**

```dart
enum SoundMode { moon, mountain, forest }
enum AppLanguage { zh, en }
enum BreathPhase { inhale, hold, exhale, transition, natural, fade, complete }
// SessionConfig: int minutes; SoundMode mode; AppLanguage language
// AudioSegment: String assetId; Duration sourceStart; Duration duration
// SessionFrame: BreathPhase phase; int? cycle; int? count; Duration elapsed; Duration remaining
SessionPlan buildSessionPlan(SessionConfig config);
// SessionPlan: SessionConfig config; List<AudioSegment> segments; Duration duration
SessionFrame frameAt(SessionPlan plan, Duration elapsed);
Duration globalPosition(SessionPlan plan, int index, Duration localPosition);
Future<AudioCatalog> loadAudioCatalog(AssetBundle bundle);
// AudioCatalog.asset(String id) -> AudioAsset (path and exact Duration)
int? parseCustomMinutes(String input);
// AppPreferences: int minutes; SoundMode mode; ThemeMode themeMode; AppLanguage? languageOverride
// PreferencesStore: Future<AppPreferences> load(); Future<void> save(AppPreferences value)
AppLanguage resolveLanguage(String systemLanguageCode, AppLanguage? override);
```

- [ ] 写失败测试，固定以下断言：

```dart
for (var m = 2; m <= 60; m++) {
  expect(buildSessionPlan(config(minutes: m)).duration, Duration(minutes: m));
}
expect(phaseAt(0), BreathPhase.inhale);
expect(phaseAt(4), BreathPhase.hold);
expect(phaseAt(11), BreathPhase.exhale);
expect(phaseAt(19), BreathPhase.inhale);
expect(phaseAt(76), BreathPhase.transition);
expect(phaseAt(80), BreathPhase.natural);
expect(phaseAt(585), BreathPhase.fade); // 默认 10 分钟
expect(phaseAt(600), BreathPhase.complete);
for (final s in ['', '1', '61', '2.5', 'abc']) { expect(parseCustomMinutes(s), isNull); }
expect(resolveLanguage('zh', null), AppLanguage.zh);
expect(resolveLanguage('fr', null), AppLanguage.en);
expect(resolveLanguage('zh', AppLanguage.en), AppLanguage.en);
```

测试本地 helper `config({int minutes = 10})` 构造 moon/zh 配置；`phaseAt(int seconds)` 调用默认计划的 frameAt。另测 18→19、75→76、79→80、584→585、599→600 秒边界、负数与超范围进度钳制、片段边界全局进度连续；损坏设置恢复默认；保存往返一致；两个 ARB 非元数据键完全相同且无空值。

- [ ] 运行 `flutter test test/session_plan_test.dart test/preferences_test.dart test/localization_test.dart`，确认接口缺失或行为不符时失败。
- [ ] 实现上述文件。序列固定 `guide80 + bed60×(M−2) + bed[0:25] + fade15`；帧和剩余时间只接受实际媒体进度。默认 10 分钟、moon、ThemeMode.system、languageOverride=null；持久化只包含设置。
- [ ] 运行同一组测试，要求全部通过；执行 `flutter gen-l10n` 成功。
- [ ] 提交：`git add lib/session lib/audio/audio_catalog.dart lib/settings lib/l10n l10n.yaml test; git commit -m "feat: add deterministic sessions and bilingual preferences"`。

## Task 3 接入唯一音频服务及系统打断

**Files:** 创建 `lib/audio/audio_port.dart`、`lib/audio/just_audio_port.dart`、`lib/audio/session_audio_handler.dart`、`test/support/fake_audio_port.dart`、`test/session_audio_handler_test.dart`；修改 `android/app/src/main/AndroidManifest.xml`、`android/app/src/main/kotlin/com/qiyanzhixing/quicksleep/MainActivity.kt`、`ios/Runner/Info.plist`、`lib/main.dart`。

**Interfaces:** `AudioPort` 提供 `load(List<AudioSegment>, AudioCatalog)`、`play()`、`pause()`、`stop()`、`dispose()`，均返回 Future<void>，以及 `Stream<PortSnapshot> snapshots`；PortSnapshot 包含 int index、Duration position、bool playing、bool completed、String? error。`SessionAudioHandler(AudioPort, AudioCatalog)` 继承 BaseAudioHandler，提供 `start(SessionConfig)`、`play()`、`pause()`、`stop()`、`preview(SoundMode, AppLanguage)`、`stopPreview()`、`onInterruption(bool began)`、`onHeadphonesDisconnected()`，均返回 Future<void>；`Stream<SessionSnapshot> sessionStates` 包含 SessionConfig? config、SessionFrame? frame、SessionStatus status、String? error。SessionStatus 为 idle、loading、playing、paused、completed、error；无活动练习时 config/frame 为 null。

- [ ] 写失败测试并实现 FakeAudioPort 记录命令、手动推送状态和延迟 load。断言：连续 start 只保留最后一次加载；过期 load 不触发 play；pause 后 fake position 不变则 remaining 不变；打断结束不调用 play；耳机断开调用 pause；preview 后 start 先停止试听；stopPreview 不停止已经开始的 session；completed 只停止不重播；错误产生 error 状态并停止；锁屏进度为全局进度而非当前片段进度。

```dart
// last_start_wins: 两个 load 按相反顺序完成，FakeAudioPort 记录 playCalls
expect(port.playCalls, 1);
expect(lastState.config, secondConfig);
// interruption_requires_manual_resume: began=true 再 false，之前已经播放一次
expect(port.playCalls, 1);
expect(lastState.status, SessionStatus.paused);
// decoder_failure_is_visible
expect(lastState.status, SessionStatus.error);
expect(lastState.error, isNotEmpty);
```

- [ ] 运行 `flutter test test/session_audio_handler_test.dart`，确认先失败。
- [ ] 实现适配器和 handler，用可取消的请求序号处理加载竞争，关闭原生重复与随机播放，预载有限队列；不靠 Dart 定时器切换、淡出或停止。显式处理所有打断，关闭播放器默认自动恢复。配置 Android 媒体前台服务、iOS audio 后台模式；系统只暴露播放、暂停和停止，整段 metadata 总时长为 minutes×60 秒。包名暂定 `com.qiyanzhixing.quicksleep`。
- [ ] 运行同一组测试并全部通过；检查 Android 无录音权限、iOS 无麦克风使用声明，无线上音频 URL。
- [ ] 提交：`git add lib/audio lib/main.dart test android ios; git commit -m "feat: support offline background playback and interruptions"`。

## Task 4 实现 Figma 双主题界面和交互

**Files:** 创建 `lib/app.dart`、`lib/theme/app_theme.dart`、`lib/ui/home_screen.dart`、`sound_mode_sheet.dart`、`duration_sheet.dart`、`session_screen.dart`、`settings_screen.dart`、`breathing_orb.dart`（后六个均在 lib/ui）；创建 `assets/visual/`、`assets/fonts/`、`test/ui_flow_test.dart`、`test/ui_layout_test.dart`；修改 `lib/main.dart`、`pubspec.yaml`。

**Interfaces:** `QuickSleepApp({required SessionAudioHandler audio, required PreferencesStore preferences})`；`HomeScreen({required SessionAudioHandler audio, required AppPreferences preferences, required ValueChanged<AppPreferences> onPreferencesChanged})`。其余页面通过此设置流和 handler 交互，不另建播放器；SessionScreen 读取 sessionStates，BreathingOrb 接收 SessionFrame 与 reduceMotion。

- [ ] 写失败界面测试：首次选择10分钟与moon；自定义2和60可保存、无效值不保存；选模式立即保留；关闭声音页停止试听；双击开始只出现一次 session；暂停/继续/结束正确调用同一 handler；设置语言立即翻译界面、下一会话采用新语言、当前会话不变；持久化主题与语言可恢复。

```dart
// english_small_screen_large_text_has_no_overflow: 320×568，2.0倍文字，English
expect(tester.takeException(), isNull);
// closing_sound_sheet_stops_preview: 点试听后关闭弹层，检查 FakeAudioPort
expect(port.stopCalls, greaterThanOrEqualTo(1));
// language_change_preserves_active_session
expect(lastState.config!.language, AppLanguage.zh);
expect(savedPreferences.languageOverride, AppLanguage.en);
```

- [ ] 运行 `flutter test test/ui_flow_test.dart test/ui_layout_test.dart`，确认页面尚未实现时失败。
- [ ] 实现页面和本地素材。在 390×844 比对已确认 Figma，按安全区域排版；提取正确深浅主题变量、原图导出的球体与图标。设置入口放在页头，设置本身在独立页面。导出字体与素材，保存许可，不使用临时 Figma URL、远程字体或截图整页替代界面。减少动态效果时取消缩放动画。
- [ ] 增加并运行窄屏与放大测试：320×568 和 390×844，各覆盖中英、深浅、文字比例1.0和2.0，断言无 Flutter overflow 错误且主要按钮可滚动到达；比较指定截图，检查没有固定“9:41”或假系统状态栏。执行完整 `flutter test` 全部通过。
- [ ] 提交：`git add lib assets pubspec.yaml pubspec.lock test; git commit -m "feat: implement themed bilingual relaxation screens"`。

## Task 5 平台验证 推送与交付

**Files:** 创建 `.github/workflows/ci.yml`、`integration_test/session_smoke_test.dart`、`docs/verification.md`、`docs/audio-sources.md`；更新 `README.md`。

**Interfaces:** CI 对同一提交分别报告 analyze/test、Android debug APK、macOS iOS simulator build。`docs/verification.md` 记录命令、提交 SHA、平台、结果和未执行原因；README 提供两平台运行方式、音频再生成方式、合成内容说明和已知限制。

- [ ] 写集成用例：选择2分钟断网播放，结束后 remaining=0、status=completed 且不重播；预置暂停恢复测试，验证媒体进度停住。先运行 `flutter test integration_test/session_smoke_test.dart -d <实际已发现设备ID>`，记录失败结果；没有设备时明确未执行。
- [ ] 配置 CI 并修复实测问题。依次运行 `dart format --output=none --set-exit-if-changed lib test integration_test`、`flutter analyze`、`flutter test`、音频校验、`flutter build apk --debug`；macOS 执行 `flutter build ios --simulator --debug`。任一命令没有实际成功记录，不能标为通过。
- [ ] 在可用 Android 与 iOS 真机各验证10分钟锁屏全流程、后台片段衔接、电话、有线与蓝牙断开、手动恢复、强制结束后不自启。记录实际结果；浏览器预览或单元测试不能替代这些检查。没有设备或签名授权时继续其他验证，并把缺口明确列为待验证。
- [ ] 整分支独立代码审查，关注音频竞争、总时长、资源完整性、权限与中英资源；修复后重跑受影响检查和全套自动化检查。
- [ ] 提交：`git add .github integration_test docs README.md; git commit -m "test: add platform checks and setup documentation"`。重新读取远端 main，保留已有提交；优先正常 Git 推送。若 SSH 不可用，使用已连接 GitHub 的 blob/tree/commit/ref 路径等价发布，禁止强制覆盖已有历史。首次完整实现可快进更新 main；如远端有并发变更，先合并和复测再推送。
- [ ] 验证远端 SHA 与交付提交一致，跟踪该 SHA 的 CI 到终态并处理授权范围内可恢复失败。交付代码链接、通过的检查、实际可用 Android 产物与 iOS 验证缺口；不宣称已经提供未签名或未生成的安装包。

## 执行方式与已知限制

推荐 **Native**：由同一实施者顺序完成这五项紧密相连的任务，再进行一次独立整分支审查，减少接口来回交接。也可选 **Subagent-driven**：每项由新实施者及新审查者执行，检查更细但耗时与上下文成本更高。

当前缺少 Flutter/Android 工具链与语音生成依赖，任务1首先验证这些条件；官方 Flutter 源码能访问，测试过的发布目录返回404，需要解决安装路径。iOS 的 Xcode 编译、签名与真机验证需要 macOS；不索取或读取账号密钥，不自行购买服务或签署额外协议。失败会报告具体阻碍并保留已完成工作，不把代码推送等同于两平台已安装验证。

请审阅计划并选择 Native（推荐）或 Subagent-driven。确认后才开始产品实现。
