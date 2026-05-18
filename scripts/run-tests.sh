#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild \
  -project TomatoClock.xcodeproj \
  -scheme TomatoClock \
  -destination 'platform=macOS' \
  test
