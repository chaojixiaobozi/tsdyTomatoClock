#!/usr/bin/env bash
# 构建 Release 版 TsdyTomatoClock.app，并生成可安装的 DMG（拖到「应用程序」即可）。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="TomatoClock.xcodeproj"
SCHEME="TomatoClock"
CONFIGURATION="Release"
VERSION="1.0.0"
STAGING="$ROOT/dist/staging"
OUT_DMG="$ROOT/dist/TsdyTomatoClock-${VERSION}.dmg"
DERIVED="$ROOT/dist/DerivedData"

rm -rf "$ROOT/dist"
mkdir -p "$STAGING"

echo "==> 编译 Release（签名：本地 ad hoc “-”）…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  -destination "generic/platform=macOS" \
  CODE_SIGN_IDENTITY="-" \
  build

APP="$DERIVED/Build/Products/$CONFIGURATION/TsdyTomatoClock.app"
if [[ ! -d "$APP" ]]; then
  echo "错误：未找到 $APP"
  exit 1
fi

echo "==> 准备 DMG 内容…"
ditto "$APP" "$STAGING/TsdyTomatoClock.app"
ln -sf /Applications "$STAGING/Applications"

echo "==> 生成 DMG: $OUT_DMG"
mkdir -p "$ROOT/dist"
hdiutil create \
  -volname "TsdyTomatoClock" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$OUT_DMG"

echo "==> 清理中间文件…"
rm -rf "$DERIVED" "$STAGING"
echo ""
echo "产物: $OUT_DMG"
echo ""
echo "安装提示："
echo "  - 本地 Debug（.build_cli）与 DMG（Release）是两次独立编译，互不影响。"
echo "  - 若「应用程序」里已有旧版，请先 ⌘Q 退出并删除 /Applications/TsdyTomatoClock.app，再拖入新 DMG。"
echo "  - 也可先挂载 DMG，直接双击卷内 TsdyTomatoClock.app 验证 Release 包。"
echo ""
echo "    1. 双击打开 $OUT_DMG"
echo "    2. 将 TsdyTomatoClock.app 拖入窗口中的「应用程序」"
echo "    3. 首次打开若提示「无法验证开发者」：系统设置 → 隐私与安全性 → 仍要打开"
