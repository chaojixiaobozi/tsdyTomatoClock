# TsdyTomatoClock

运行在 **macOS** 上的本地番茄钟：专注 → 短休 →（周期性）长休；数据本地存储，不依赖账号与云端。

- **产品说明**：[`docs/PRD.md`](docs/PRD.md)  
- **技术约定**：[`docs/TECH_SPEC.md`](docs/TECH_SPEC.md)  
- **协作与编码基线**：[`AGENTS.md`](AGENTS.md)

## 环境要求

- **macOS 12（Monterey）及以上**
- **Xcode**（建议与本工程 LastUpgradeCheck 接近的版本，含 Swift 5 / SwiftUI）

## 在 Xcode 中开发

1. 打开 `TomatoClock.xcodeproj`
2. Scheme 选择 **TomatoClock**，运行目标 **My Mac**
3. **⌘R** 运行，**⌘U** 跑单元测试 + UI 测试

主界面产物名为 **TsdyTomatoClock**（`PRODUCT_NAME`）；工程内 target 名仍为 `TomatoClock`。

## 命令行

**跑测试**（与 CI 一致思路）：

```bash
cd /path/to/tsdyTomatoClock
bash scripts/run-tests.sh
```

或直接：

```bash
xcodebuild -project TomatoClock.xcodeproj -scheme TomatoClock -destination 'platform=macOS' test
```

**本地 Debug 构建并启动**（示例：固定 DerivedData 路径便于找到 `.app`）：

```bash
xcodebuild -project TomatoClock.xcodeproj -scheme TomatoClock -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath ./.build_cli build \
  && open ./.build_cli/Build/Products/Debug/TsdyTomatoClock.app
```

## 打包 DMG

```bash
bash scripts/package-dmg.sh
```

成功后产物在 **`dist/TsdyTomatoClock-1.0.0.dmg`**（版本号以脚本内 `VERSION` 为准）。DMG 内含 **`TsdyTomatoClock.app`**，拖到「应用程序」即可。

## 工程结构（简要）

| 路径 | 说明 |
|------|------|
| `TomatoClock/Domain/` | 纯 Swift 状态机与配置，无 SwiftUI |
| `TomatoClock/Features/` | SwiftUI 界面与 ViewModel |
| `TomatoClock/Services/` | 通知、持久化等 |
| `TomatoClock/Assets.xcassets/` | 含 `AppIcon` 等资源 |
| `TomatoClockTests/` | 逻辑单元测试 |
| `TomatoClockUITests/` | UI 测试 |
| `scripts/` | 测试、DMG 等脚本 |

## 图标缓存说明

若更新 `AppIcon` 后 Dock 仍显示旧图标，可先退出应用，必要时执行 `killall Dock` 刷新 Dock，或删除「应用程序」内旧包后再安装新构建。
