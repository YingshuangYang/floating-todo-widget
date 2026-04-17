#!/bin/zsh
set -euo pipefail

ROOT="/Users/yys/Documents/skills"
APP_NAME="FloatingTodoWidget.app"
APP_DIR="$ROOT/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SOURCE_BIN="$ROOT/.build/arm64-apple-macosx/release/FloatingTodoWidget"
ICON_FILE="$ROOT/AppIcon.icns"

if [[ ! -x "$SOURCE_BIN" ]]; then
  echo "Release binary not found: $SOURCE_BIN" >&2
  echo "Run: env CLANG_MODULE_CACHE_PATH=$ROOT/.build/module-cache swift build -c release" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$SOURCE_BIN" "$MACOS_DIR/FloatingTodoWidget"
if [[ -f "$ICON_FILE" ]]; then
  cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi
chmod +x "$MACOS_DIR/FloatingTodoWidget"

echo "Created: $APP_DIR"
