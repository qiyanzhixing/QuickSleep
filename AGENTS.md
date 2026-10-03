# QuickSleep 开发约定

- Android 客户端使用 Kotlin / Jetpack Compose，iOS 客户端使用 Swift / SwiftUI。不引入 Flutter、React Native 或跨平台业务运行时。
- `legacy/` 为历史参考；不要修改，也不要让新应用依赖其客户端代码。
- 两端行为以 `docs/product/native-rewrite.md` 为准，平台差异在 `docs/architecture/native.md` 记录。
- 共用素材、授权记录和双语源文案放在 `shared/`；运行 `python scripts/prepare_assets.py` 恢复并生成原生资源。
- 音频播放由原生播放器决定进度和结束，UI 计时器不能切换音轨或停止练习。
- 业务逻辑、时序、输入校验和资源完整性需要测试；纯视觉 UI 修改不强制 TDD，不增加展示细节测试。
- 记录实际执行过的验证。Windows 无法验证 Xcode；模拟器不能代替后台与打断的真机验收。

## Superpowers 使用规则

- 按当前任务需要使用技能，无需每次显式授权；用户明确使用、跳过或停止某技能时遵循用户要求。
- 新功能、架构、数据模型或接口设计存在需要讨论的取舍时使用 brainstorming；排查缺陷、测试失败或异常时使用 systematic-debugging。
- 明确需求的多步实施按需使用 writing-plans 及执行技能；普通知识问答、代码解释和明确的小范围修改不自动启动完整工作流。
- 每次只加载当前阶段需要的技能，不自动扩展为设计、计划、实现、审查、提交全流程。
- 已确认需求与已完成阶段继续沿用，不重新询问；不因新会话执行 using-superpowers 全局启动流程。
- 首次启用技能时简短说明名称与用途。先看相关代码及示例再提问，澄清影响行为、数据结构和接口的关键歧义；区分确认要求与建议。
- 本节规则优先于技能中的通用自动触发和流程扩展要求。
