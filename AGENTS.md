# AGENTS — 协作说明

供人与自动化助手在本仓库协作时快速对齐上下文。细节以 `docs/PRD.md`、`docs/TECH_SPEC.md` 为准。

## 项目背景

- **产品**：macOS 本地轻量番茄钟（工作 → 短休 → 长休），无账号、无云端依赖。
- **目标**：开箱即用、状态一眼可读、到点提醒克制；一期不做协作、复杂项目、强制登录。
- **文档**：需求见 PRD；架构、测试与视觉见 TECH_SPEC。

## 技术栈

| 项 | 约定 |
|----|------|
| 平台 | macOS 12+，Swift 5，SwiftUI |
| 计时 | 结束时刻 + 暂停偏移（单调时间），避免纯 Timer 累加漂移 |
| 存储 / 通知 | UserDefaults；UserNotifications |
| 结构 | Domain（纯逻辑）/ ViewModel / Services / SwiftUI 视图 |
| 测试 | XCTest（逻辑）+ XCUITest（UI）；CI 需 `xcodebuild test` 通过 |
| 视觉 | 番茄色系、低饱和；动效 ≤300ms；跟随系统浅深 |

## 代码规范

1. **分层**：业务状态机与剩余时间计算放在 **Domain**，禁止依赖 SwiftUI；UI 与副作用经 ViewModel / Services。
2. **可测性**：Domain 行为变更须补充或更新 **单元测试**；可注入时钟/时间抽象，避免在逻辑里写死 `Date()` 难以测。
3. **UI 测试**：关键控件设 **`accessibilityIdentifier`**，少绑中文文案。
4. **改动范围**：只改任务相关文件，不做无关重构；命名与现有模块一致。
5. **体验**：破坏性操作（如重置）需二次确认；通知权限被拒时界面有引导（PRD 验收）。
6. **隐私**：默认不上传数据；本地存储范围与路径在实现或注释中可辨识即可。
