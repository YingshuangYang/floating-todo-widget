# Floating Todo Widget

An Apple-inspired floating desktop todo widget for macOS, built with SwiftUI.

![Floating Todo Widget screenshot](docs/app-screenshot.png)

## Features

- Floating always-on-top desktop widget window
- Apple-style polished UI with soft glass panels
- Editable daily task list
- Strike-through styling for completed tasks
- Numbering only for rows that contain task text
- Live completion ring and summary stats
- Press `Enter` to move to the next task row
- Auto-save with `UserDefaults` so tasks persist between launches
- Double-clickable `.app` packaging support

## Project Structure

- `Sources/FloatingTodoWidget/main.swift`: the SwiftUI desktop widget app
- `Package.swift`: Swift Package Manager configuration
- `package_app.sh`: packages the release build as `FloatingTodoWidget.app`
- `Info.plist`: app bundle metadata
- `make_icon.swift`: generates the assignment-style macOS app icon
- `daily-todo-widget.html`: original standalone HTML version

## Run Locally

```bash
swift run
```

## Build Release

```bash
env CLANG_MODULE_CACHE_PATH=/Users/yys/Documents/skills/.build/module-cache swift build -c release
```

## Package as a macOS App

```bash
zsh package_app.sh
```

This creates:

```bash
/Users/yys/Documents/skills/FloatingTodoWidget.app
```

## Install

Copy the generated app into `Applications`:

```bash
cp -R /Users/yys/Documents/skills/FloatingTodoWidget.app /Applications/FloatingTodoWidget.app
```

## Notes

- The widget is designed for macOS 13+
- Build artifacts and local packaged apps are ignored by git
- The app does not auto-launch at login
