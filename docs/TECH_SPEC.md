# Mac 番茄钟 — 技术方案（简版）

> 依据 `PRD.md`（含 **v0.2** 第 9 节、**v0.3** 第 10 节）；目标：**实现简单、界面简洁、番茄色系、自动化测试保障交付**。

---

## 1. 技术选型（推荐）

| 维度 | 选择 | 说明 |
|------|------|------|
| 语言 / UI | **Swift 5 + SwiftUI** | 单工程、与系统窗口/通知/深浅色集成成本最低，符合 PRD「原生级体验」。 |
| 最低系统 | **macOS 12（Monterey）+** | 与 PRD 一致；Intel / Apple Silicon 通用 arm64 + x86_64。 |
| 计时实现 | **单调时钟** | `Date` / `CFAbsoluteTimeGetCurrent()` 记录「阶段结束时刻」与暂停偏移；避免纯 `Timer` 累加导致可见漂移。 |
| 本地存储 | **UserDefaults**（或 App Group 预留） | 配置、当日完成数、**按日历史字典**（`YYYY-MM-DD` → 完成数）；无复杂 DB。 |
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
- **内容**：状态机迁移表、暂停/继续时间、跳过与重置、当日计数边界、**跨日写入历史 / 历史读取**（单测 mock 日期与 `Calendar`）。
- **本地**：Xcode `⌘U` 或 `xcodebuild test`。
- **CI**：GitHub Actions（`macos-12` 或更高 runner）执行：

```bash
xcodebuild -scheme TomatoClock -destination 'platform=macOS' test
```

（Scheme 名以工程为准，可改为实际名称。）

### 5.2 UI 测试（XCUITest）

- **Target**：`TomatoClockUITests`。
- **可测点**：启动后主界面存在、默认剩余时间展示、开始/暂停按钮可点、（可选）打开设置后保存参数回到主页仍可读；**v0.3**：历史按钮在设置左侧、月历 sheet 可开、月份切换控件存在。
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
├── Features/History/        # 月历历史（v0.3）
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
| 按天历史（v0.3） | `PomodoroPersistence` 日字典 + `Features/History` 月历 |
| 浅色/深色 | Asset 颜色 + 系统语义色 |
| 计时误差 | 结束时刻模型 + 单调时间 |
| 无障碍 / 键盘 | SwiftUI 默认焦点链 + 主要按钮可 Tab |

---

## 8. 文档修订

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1 | 2026-05-18 | 初稿：简架构、SwiftUI、番茄色与双测策略 |
| 0.2 | 2026-05-19 | 追加：阶段结束前置窗口、待确认流转、时长预设（见第 9 节） |
| 0.3 | 2026-05-29 | 追加：按天番茄完成数历史、月历视图（见第 10 节） |

---

## 9. v0.2 技术落点（对齐 PRD 第 9 节）

本节为 **v0.2** 实现说明；与上文冲突时以本节为准。

### 9.1 阶段结束：主窗口前置

- **触发**：仅当**当前阶段自然计时到点**（与 PRD 一致：是否在「跳过」时也前置由产品拍板；**技术默认**：仅自然结束触发前置，跳过不抢焦点）。
- **实现**：在 **AppKit** 侧对主窗口执行激活与前置，例如 `NSApplication.shared.activate(ignoringOtherApps: true)` 后 `NSWindow.makeKeyAndOrderFront(nil)`（或通过 `NSApp.windows` / `NSWindow` 引用拿到 `WindowGroup` 对应窗口）。SwiftUI 中可用 `NSApplicationDelegate` / `WindowAccessor`（`NSViewRepresentable` 取 `view.window`）或 `@EnvironmentObject` 注入 `WindowController` 协议，由 **ViewModel** 在 Domain 报告「自然结束」后调用，避免 Domain 依赖 AppKit。
- **降级**：若无法取得有效 `NSWindow` 或系统拒绝激活，则仅保留通知 + 文案提示「请打开番茄钟确认下一阶段」；不阻塞计时状态机。
- **测试**：单元测试不依赖真实窗口；可协议化 `WindowPresentation` 并在单测里断言「自然结束时被调用一次」。

### 9.2 阶段流转：待确认再进入下一阶段

- **Domain 调整**：在「自然结束」与「开始下一段」之间增加显式状态，例如：
  - `runState` 扩展 **`awaitingAdvance`**（或等价命名），表示本段已结束、**未**开始下一段倒计时；**`running`** 仅表示当前段正在倒计时。
  - 原「到点即 `acknowledgeSegmentComplete` 并写入下一段 `segmentDeadline`」拆成两步：**(A)** `completeCurrentSegmentNaturally(at:)` → 进入 `awaitingAdvance`，并确定**下一段目标阶段**（工作/短休/长休）但**不写新 deadline**；**(B)** `confirmAdvance(at:)` → 切换 `phase`、进入 `running` 并设置新 `segmentDeadline`。
  - **跳过**：建议 **直接执行 (A)+(B)**（即跳过仍连续切换且不进入 `awaitingAdvance`），与 PRD「手动确认」仅约束自然结束一致；写入单测与验收。
- **UI**：自然结束后主区展示「本阶段已结束」+ 主按钮 **「进入下一阶段」**（`accessibilityIdentifier` 如 `timer.confirmAdvanceButton`）；支持 **键盘默认焦点** 在该按钮上（`defaultFocus` / `@FocusState`，以 macOS 12 可用 API 为准）。
- **通知**：自然结束时仍发通知；待确认期间**不**为下一段调度「整段结束」的定时通知，待用户确认后再调度。

### 9.3 时长预设：一键切换

- **Domain / 配置**：增加 **`PomodoroPreset`**（`enum` 或命名常量表），与 `PomodoroConfig` 映射如下（单位秒，与 PRD 表一致）：

| 预设 | work | shortBreak | longBreak |
|------|------|------------|-----------|
| classic255 | 1500 | 300 | 900 |
| fortyfive15 | 2700 | 900 | 900 |
| fiftytwo17 | 3120 | 1020 | 1800 |

- **轮次**：`pomodorosUntilLongBreak` **默认仍为 4**，切换预设**不自动改写**（与 PRD 可选策略一致）；若设置页单独保存该字段，与预设独立。
- **UI**：主界面或设置区提供三个 **Segmented / 按钮** 一键应用；仅在 **`idle` 或 `awaitingAdvance`**（若允许在「待确认」时改参数，需明确是否重置待确认态；**默认仅 `idle` 可切换预设**）调用 `engine.updateConfig` 并 `Persistence.save`。
- **持久化**：`UserDefaults` 增加可选键 `lastSelectedPreset`（字符串），便于下次启动恢复展示。

### 9.4 测试与 CI

- **单元测试**：覆盖「自然结束 → awaitingAdvance → confirm → running」「跳过不进入 awaiting」「预设应用后三段时间与上表一致」。
- **UI 测试**：自然结束路径若难以在 CI 等时，可测「空闲时点击某预设后剩余时间变化」与「确认按钮存在并可点」（结合短时长配置或 mock，按实现取舍）。
- **CI**：与现有一致；新增 Domain 逻辑须随 PR 通过单测。

### 9.5 与旧版第 4 节的关系

- 上文第 4 节「到点即 `acknowledgeSegmentComplete` 连续流转」在 v0.2 由 **9.2** 取代；实现时删除或分支旧路径，避免双行为。

---

## 10. v0.3 技术落点（对齐 PRD 第 10 节）

本节为 **v0.3** 实现说明；与上文冲突时以本节为准。

### 10.1 数据模型与持久化

- **日键**：沿用 `PomodoroPersistence.todayString(for:calendar:)` 的 **`YYYY-MM-DD`** 字符串，时区取 **`Calendar.current`**（与系统日历日一致）。
- **历史存储**：`UserDefaults` 新增键 **`pomodoro.dailyHistory.v1`**，值为 JSON 编码的 **`[String: Int]`**（日字符串 → 当日完成番茄数）。仅本地读写，无网络。
- **与现有键的关系**（保留 v0.1/v0.2 启动路径，避免大改）：
  - 仍保留 **`pomodoro.calendarDay.v1`** + **`pomodoro.todayCount.v1`** 作为「当前自然日」的快速读写；
  - 每次 **`save(...)`** 时同步更新历史字典中 **`calendarDay`** 对应条目为 **`todayCount`**；
  - **`loadBootstrap`** 逻辑不变：存储日与请求日不一致时返回计数 0。
- **跨日归档**：在 `TimerViewModel` 的 tick / 启动路径检测到自然日变化时，**先**将「存储日 + 存储计数」写入历史字典（若存储日非空且计数 > 0，或计数为 0 也可不写以减噪——**默认：计数 > 0 才写入**），**再**调用 `engine.rolloverCalendarDayIfNeeded` 并将新日计数持久化。
- **保留策略**：默认**不设过期删除**（单日一条 `Int`，体量可忽略）；若后续需控体积，可在 `save` 时 prune 超过 **730 天**（约两年）的键，v0.3 可不实现 prune。
- **Service API 建议**（`PomodoroPersistence` 扩展，Domain 仍不依赖 UserDefaults）：

```swift
func loadDailyHistory() -> [String: Int]
func recordDay(_ calendarDay: String, count: Int)  // upsert 单日
func count(for calendarDay: String, in history: [String: Int], todayDay: String, todayCount: Int) -> Int
// 查询某日：若 calendarDay == todayDay 优先返回内存中 todayCount，否则读 history
```

- **计数口径**（与 PRD / 现有 Domain 一致）：**仅** `PomodoroEngine.completeCurrentSegmentNaturally` 在工作阶段结束时 `todayCompletedPomodoros += 1`；**跳过工作段不计数**（见 Engine 注释）。历史与「今日完成」须同源，不在 View 层另算。

### 10.2 时区 / 改日期边界

- **正常跨日**：由 ViewModel 周期性 `todayString()` 对比 `engine.currentCalendarDay` 触发归档 + rollover（与现有 `rolloverCalendarDayIfNeeded` 衔接）。
- **用户回调系统日期**：同一日键再次写入时 **覆盖** 该键计数（last-write-wins）；不尝试合并「虚拟过去」。验收可接受。
- **时区变更**：一律以当前 `Calendar.current` 重新计算日字符串；若导致日键变化，走与跨日相同的归档逻辑。不在 v0.3 做历史键迁移。

### 10.3 UI：入口与月历

- **入口**：`TimerRootView` 顶栏 `HStack` 右侧操作区，顺序固定为 **「历史」→「设置」**（历史在左）。历史用 **`Button` + `.sheet`**（与设置并列，非塞进设置页）。
- **accessibilityIdentifier**：
  - `timer.historyButton`
  - `history.monthTitle`
  - `history.previousMonth`
  - `history.nextMonth`
  - `history.dayCell.{yyyy-MM-dd}`（每格唯一，便于 UI 测与 VoiceOver）
- **月历视图**（`Features/History/HistoryCalendarView.swift`，可选轻量 `HistoryViewModel`）：
  - 默认展示 **当前自然月**；
  - 顶部：**上一月 / 下一月** 按钮 + 年月标题（如「2026 年 5 月」）；
  - 主体：**7 列网格**（星期表头跟随 `Calendar.current.firstWeekday`，中文环境下通常为 周日至周六 或 周一至周日，以系统为准）；
  - **当月内日期格**：上行日期数字，下行完成数；**非当月占位格**（月初/月末补位）留空或弱化，不展示计数；
  - **无记录日**：仅显示日期数字，**不显示「0」**（与 PRD「0 或留空」取留空方案，全产品一致）；
  - **今日**：可用细边框或次要强调色区分（可选，不抢主计时区视觉）。
- **数据绑定**：打开 sheet 时传入 `PomodoroPersistence.loadDailyHistory()` + 当前 `todayDay` / `todayCount`；切换月份仅改 UI 状态，不写盘。关闭 sheet 无需特殊持久化。
- **键盘**：月份按钮与关闭/返回可 Tab 聚焦；`defaultFocus` 可落在月历容器或「下一月」旁，以 macOS 12 可用 API 为准。

### 10.4 架构边界

| 层 | 职责 |
|----|------|
| **Domain** | 不变：仍维护 `todayCompletedPomodoros` 与 `rolloverCalendarDayIfNeeded`；**不** import 历史字典 |
| **Services** | `PomodoroPersistence` 读写日字典；归档上一日 |
| **ViewModel** | `TimerViewModel`：完成自然工作段 / tick 跨日后 `save`；`HistoryViewModel`（若有）：按年月向 Persistence 取数并生成月网格模型 |
| **UI** | 月历纯展示 + 月份切换；不在 View 内改计数 |

**月网格模型**（可放 History feature 内纯 Swift 结构体，便于单测）：

```swift
struct HistoryMonthGrid {
    let year: Int
    let month: Int
    /// 固定 42 或 6×7 格，含 leading/trailing 占位；每格 optional day + count
    let cells: [HistoryDayCell]
}
```

由 `Calendar` 的 `range(of: .day, in: .month, ...)` 与 `ordinality` 生成，单测用固定 `Calendar`（如 `gregorian` + 固定 timeZone）断言格数与某日 count。

### 10.5 测试与 CI

- **单元测试**（`TomatoClockTests`）：
  - Persistence：`save` 后 `loadDailyHistory` 含对应日；跨日归档后前一日在历史中、今日键为 0；
  - 查询逻辑：「今天」优先读 engine 计数而非陈旧 history 同键；
  - `HistoryMonthGrid`（若抽取）：给定年月与 history，某格 count 正确。
- **UI 测试**：
  - 主界面存在 `timer.historyButton`，且布局在 `timer.settingsButton` 左侧（可用相对顺序或 snapshot 区域粗测）；
  - 点击历史打开 sheet，存在 `history.monthTitle` 与月份切换按钮；
  - 可选：注入测试 defaults 后断言某 `history.dayCell.yyyy-MM-dd` 标签含完成数。
- **CI**：与现有一致；新增 Persistence / 网格逻辑须随 PR 通过单测。

### 10.6 明确不实现（v0.3）

- CSV 导出、iCloud、Core Data/SQLite 迁移。
- 周合计、月合计行、图表组件。
- 按任务/标签拆分的历史维度。
