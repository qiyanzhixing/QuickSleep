# QuickSleep UI 设计说明

QuickSleep 的 UI 设计维护在 [Figma 设计文件](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S)。Android 使用 Kotlin / Jetpack Compose，iOS 使用 Swift / SwiftUI，分别按同一份设计实现。

## 设计入口与依据

| 页面 | Figma 节点 | 用途 |
| --- | --- | --- |
| 深色准备页 | [01 · 准备 / Ready（5:8）](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S?node-id=5-8) | 夜间主题首页 |
| 浅色准备页 | [01 · 准备 / Ready · Light（10:56）](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S?node-id=10-56) | 浅色主题首页 |
| 双主题声音选择 | [QuickSleep · 声音模式 · 双主题（26:182）](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S?node-id=26-182) | 声音选择弹层及两种主题对照 |
| 深色声音选择页 | [声音模式 / Sound modes · Night（26:188）](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S?node-id=26-188) | 深色弹层详情 |
| 浅色声音选择页 | [声音模式 / Sound modes · Light（26:293）](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S?node-id=26-293) | 浅色弹层详情 |

2026-10-03 通过 Figma 连接读取了三个主节点的结构，确认以上节点名称、子页面和尺寸。该检查确认设计入口有效，不代表完成原生界面的视觉验收。

- **视觉依据**：Figma 中对应主题的页面、组件和变量；本文用于定位与说明。
- **行为依据**：[原生产品规格](../product/native-rewrite.md)，包括时长、试听、呼吸阶段和播放控制。
- **平台实现**：[原生架构](../architecture/native.md)，记录后台播放、系统打断等平台差异。
- **历史参考**：`legacy/` 保留旧实现及设计记录；当前开发使用上述入口和原生规格。

目前尚未在本说明中确认练习页、设置页、自定义时长页的独立 Figma 节点。这些页面按产品规格和现有视觉风格实现；后续补充设计时应更新本表，不能把现有实现截图视为已确认的 Figma 设计。

## 页面结构与布局基准

准备页从上到下为品牌、标题与方法说明、呼吸球、时长选择、时长包含引导与淡出的说明、当前声音卡片、开始按钮、锁屏播放提示。默认时长为 10 分钟，提供 5 / 10 / 15 分钟和自定义入口。

声音选择使用底部弹层：标题与关闭操作、说明、三个声音卡片、底部提示。声音模式为月下轻语、山间静心、林间晚风。选择与试听的行为按产品规格执行：本地试听 8 秒，关闭弹层停止试听。

已读取的 Figma 页面采用以下基准，作为正常字号下的布局参考：

| 项目 | Figma 参考尺寸 |
| --- | --- |
| 页面画板 | 390 × 844 |
| 内容左右留白 / 内容宽度 | 24 / 342 |
| 准备页呼吸球组件 | 134 × 134 |
| 时长选项 | 高 44 |
| 准备页声音卡片 | 342 × 134 |
| 开始按钮 | 342 × 58 |
| 声音弹层 | 高 628 |
| 弹层声音卡片 | 342 × 100，卡片间距 12 |

画板尺寸不限制设备尺寸。Compose 使用 dp / sp，SwiftUI 使用 point 与动态字体；小屏、长英文和大字模式允许换行、增加高度及滚动。Figma 中的状态栏、灵动岛和手势条是设备示意，由系统实际绘制。

## 主题、字体与素材

以下色值为当前原生实现沿用的设计基准。后续修改需核对 Figma 对应主题的变量与实际画面，并同步两端。

| 语义 | 夜间 | 浅色 |
| --- | --- | --- |
| 页面背景 | `#080D1B` | `#F7F4F0` |
| 卡片表面 | `#131A2C` | `#EDE7EF` |
| 强调色 | `#B6A2EF` | `#78618F` |
| 主要文字 | `#E9E5FB` | `#332C3F` |
| 次要文字 | `#BBB5D7` | `#60536F` |
| 强调按钮文字 | `#19132B` | `#FCF8FF` |

文字使用随包提供的 Noto Serif SC 与 Noto Sans SC；字体与授权记录位于 `shared/assets/fonts/` 和 `shared/assets/licenses/`。界面文案的双语源文件为 `shared/localization/zh.json`、`en.json`，以相同语义键维护。

Figma 导出的视觉素材位于 `shared/assets/visual/`，包括两种主题的呼吸球、锁图标和选择状态图。当前两端复用呼吸球 PNG；锁图标及选择控件按各端现有实现使用导出素材或原生图标。素材目录不表示每个文件都已被两个客户端使用。

在仓库根目录运行 `python scripts/prepare_assets.py` 恢复字体并生成原生资源。编辑共用源素材与文案，再生成客户端资源；应用运行时从本地资源读取。

## 原生代码对应关系

| 内容 | Android | iOS |
| --- | --- | --- |
| 准备页与练习状态 | [QuickSleepScreen.kt](../../apps/android/app/src/main/kotlin/com/qiyanzhixing/quicksleep/ui/QuickSleepScreen.kt) | [QuickSleepView.swift](../../apps/ios/QuickSleep/UI/QuickSleepView.swift) |
| 声音、时长、设置弹层 | 同上，Compose 弹层组件 | [Sheets.swift](../../apps/ios/QuickSleep/UI/Sheets.swift) |
| 主题与呼吸球 | 同上，Palette 与呼吸球组件 | [Theme.swift](../../apps/ios/QuickSleep/UI/Theme.swift) |

两端保持页面信息顺序、主题语义、声音模式和操作行为一致。系统弹层、键盘、状态栏与设置图标可采用各平台原生呈现。呼吸球状态来自实际媒体进度；减少动态效果时使用静态呈现。

## 修改与验收

1. 修改 UI 前打开对应 Figma 节点，检查主题、组件状态、字体、间距与素材；新增页面补充节点链接，并确认影响行为的需求。
2. 同步 Android 与 iOS，实现后的设计差异在本说明或架构文档中记录。
3. 对照设计检查深色 / 浅色、中文 / 英文、默认与选中状态，并检查小屏、大字、安全区域和减少动态效果。
4. 将实际截图与检查结果记入 [验证记录](../verification.md)。`docs/screenshots/native/` 是实现截图；编译或单元测试通过不能代替视觉检查。

纯视觉修改以实际渲染对照验证；涉及业务行为、时序或输入校验的修改，按项目约定补充相应测试。
