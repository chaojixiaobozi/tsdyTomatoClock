#!/usr/bin/env bash
# 构建 Release 版 TomatoClock.app，并生成可安装的 DMG（拖到「应用程序」即可）。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="TomatoClock.xcodeproj"
SCHEME="TomatoClock"
CONFIGURATION="Release"
VERSION="0.1.0"
STAGING="$ROOT/dist/staging"
OUT_DMG="$ROOT/dist/TomatoClock-${VERSION}.dmg"
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

APP="$DERIVED/Build/Products/$CONFIGURATION/TomatoClock.app"
if [[ ! -d "$APP" ]]; then
  echo "错误：未找到 $APP"
  exit 1
fi

echo "==> 准备 DMG 内容…"
ditto "$APP" "$STAGING/TomatoClock.app"
ln -sf /Applications "$STAGING/Applications"

echo "==> 生成 DMG: $OUT_DMG"
mkdir -p "$ROOT/dist"
hdiutil create \
  -volname "番茄钟 TomatoClock" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$OUT_DMG"

echo "==> 清理中间文件…"
rm -rf "$DERIVED" "$STAGING"
echo "    1. 双击打开 $OUT_DMG"
echo "    2. 将 TomatoClock.app 拖入窗口中的「应用程序」"
echo "    3. 首次打开若提示「无法验证开发者」：系统设置 → 隐私与安全性 → 仍要打开"
echo ""
echo "产物: $OUT_DMG"
