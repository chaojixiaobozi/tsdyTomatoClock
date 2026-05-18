# Mac 番茄钟 — 技术方案（简版）

> 依据 `PRD.md` v0.1；目标：**实现简单、界面简洁、番茄色系、自动化测试保障交付**。

---

## 1. 技术选型（推荐）

| 维度 | 选择 | 说明 |
|------|------|------|
| 语言 / UI | **Swift 5 + SwiftUI** | 单工程、与系统窗口/通知/深浅色集成成本最低，符合 PRD「原生级体验」。 |
| 最低系统 | **macOS 12（Monterey）+** | 与 PRD 一致；Intel / Apple Silicon 通用 arm64 + x86_64。 |
| 计时实现 | **单调时钟** | `Date` / `CFAbsoluteTimeGetCurrent()` 记录「阶段结束时刻」与暂停偏移；避免纯 `Timer` 累加导致可见漂移。 |
| 本地存储 | **UserDefaults**（或 App Group 预留） | 仅存：当日完成番茄数、用户可调参数（工作/短休/长休/每几轮长休）；满足 MVP，无复杂 DB。 |
| 通知 | **UserNotifications** | 阶段结束发本地通知；权限被拒时在界面展示引导文案（验收项）。 |
| 分发 | **一期：本地 Archive / DMG** | 签名与公证在对外分发前再补；技术栈不阻碍后续上架 Mac App Store。 |

**不做**：Electron（体积与常驻成本偏高）、纯 Web 页（系统集成弱）。若团队无 Swift 能力，备选 **Tauri 2**（Rust 核心 + 轻量 WebView），测试策略改为 Vitest + WebDriver/Playwright，本文仍以 Swift 方案为主。

---

## 2. 架构（保持简单）

```
TomatoClockApp
├── UI Layer          SwiftUI 视图 + 少量 ViewModel（ObservableObject）
├── Domain            纯 Swift：阶段状态机、剩余时间计算、轮次规则
├── Services          通知、UserDefaults 读写、可选音效
└── Resources         颜色主题、本地化字符串（一期中文）
```

- **Domain 零依赖 SwiftUI**：便于逻辑单测、可注入「时钟」协议便于假时间。
- **ViewModel** 只做：调用 Domain、触发 Service、把状态 `@Published` 给界面。

---

## 3. 界面与「番茄色」设计

**原则**：信息层级与 PRD 一致（剩余时间 > 阶段 > 次要操作）；**低饱和、长时间可看**，用色相区分阶段而非荧光高亮。

| 语义 | 色意向 | 示例用途（可在实现时微调 Hex） |
|------|--------|--------------------------------|
| 专注工作 | 成熟番茄红（略灰） | 主背景渐变一极、主按钮强调 |
| 短休 | 樱桃番茄 / 橙红 | 阶段条、环形进度 |
| 长休 | 青番茄 / 叶绿 | 阶段条、休息态背景弱渐变 |
| 暂停 | 去饱和 | 蒙层或边框，与进行中弱对比 |
| 文字 / 图标 | 跟随系统浅深 | `Color.primary` / `secondary`，保证对比度 |

动效：阶段切换 **≤ 300ms** 的淡入或轻微缩放即可；进度可用细环形或底栏条形二选一，避免同时多种强视觉。

**窗口策略（与 PRD 一致、二选一并写死）**：推荐 **关闭主窗口 = 退出应用**（MVP 最简单）；若选「菜单栏常驻」，需在单独迭代中补状态栏图标与后台计时联调。后台持续计时的前提是：用「结束时刻」模型，不依赖窗口存活。

---

## 4. 核心逻辑（可测范围）

以下放入 **Domain**，全部用 **单元测试** 覆盖：

1. 参数：工作时长、短休、长休、每 N 个番茄后长休（默认 25/5/15/4）。
2. 状态：`idle` / `running` / `paused` × 阶段 `work` / `shortBreak` / `longBreak`。
3. 行为：开始、暂停、继续、跳过当前阶段、重置本轮（重置规则在实现时固定一条简单规则并写进测试）。
4. 轮次：完成工作阶段 → 番茄计数 +1；判断是否进入长休。
5. 剩余时间：由「目标结束时间 − 当前时间 − 暂停累计」导出，单测使用固定 `Clock` 桩。

**破坏性操作**：重置等通过 **二次确认**（SwiftUI `confirmationDialog`）或单独「危险操作」样式按钮，与 PRD 一致。

---

## 5. 测试策略（自动跑逻辑 + UI）

### 5.1 逻辑单元测试（XCTest）

- **Target**：`TomatoClockTests`（依赖 Domain，不启动 App）。
- **内容**：状态机迁移表、暂停/继续时间、跳过与重置、当日计数边界（跨日可一期简化为「进程内当日」或单测 mock 日期）。
- **本地**：Xcode `⌘U` 或 `xcodebuild test`。
- **CI**：GitHub Actions（`macos-12` 或更高 runner）执行：

```bash
xcodebuild -scheme TomatoClock -destination 'platform=macOS' test
```

（Scheme 名以工程为准，可改为实际名称。）

### 5.2 UI 测试（XCUITest）

- **Target**：`TomatoClockUITests`。
- **可测点**：启动后主界面存在、默认剩余时间展示、开始/暂停按钮可点、（可选）打开设置后保存参数回到主页仍可读。
- **稳定性**：为关键控件设置 **`accessibilityIdentifier`**，避免依赖文案随语言变化。
- **CI**：与逻辑测试同一 `xcodebuild test` 命令跑完两个 Target；不依赖真机。

### 5.3 质量门禁（交付）

- PR / 主分支合并前：**CI 必须通过** 单元测试 + UI 测试。
- 一期不要求覆盖率数值 KPI，但 Domain 新增行为必须带测试用例。

---

## 6. 工程与目录建议（落地时）

```
TomatoClock/
├── App/
├── Features/Timer/          # 主界面
├── Features/Settings/       # 极简设置
├── Domain/                  # 状态机 + 时间计算
├── Services/
├── Tests/TomatoClockTests
└── UITests/TomatoClockUITests
```

---

## 7. 与 PRD 的对应关系（摘要）

| PRD 要点 | 技术落点 |
|----------|----------|
| 25/5/15、轮次、控制按钮 | Domain + SwiftUI |
| 系统通知 | `UNUserNotificationCenter` |
| 极简会话记录 | UserDefaults + 主界面展示 |
| 浅色/深色 | Asset 颜色 + 系统语义色 |
| 计时误差 | 结束时刻模型 + 单调时间 |
| 无障碍 / 键盘 | SwiftUI 默认焦点链 + 主要按钮可 Tab |

---

## 8. 文档修订

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1 | 2026-05-18 | 初稿：简架构、SwiftUI、番茄色与双测策略 |
