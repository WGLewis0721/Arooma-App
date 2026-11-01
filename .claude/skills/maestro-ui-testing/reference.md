# Maestro reference

Companion to [SKILL.md](SKILL.md). Commands marked *verified* come from Maestro's docs. Commands marked *check* were not confirmed in the docs; confirm them with `cheat_sheet` before relying on them.

## Install and start

```bash
# CLI (verify the install command against the current Maestro docs first)
maestro --version

# MCP server for agents (stdio)
maestro mcp
```

Claude Code: `claude mcp add maestro -- maestro mcp`

Generic MCP client entry (when `maestro` is on PATH):

```json
{"mcpServers":{"maestro":{"command":"maestro","args":["mcp"]}}}
```

Claude Desktop needs the full path to `maestro` (`which maestro`) and `JAVA_HOME` in the `env` block.

## iOS simulator setup

```bash
xcrun simctl list devices available            # find an iPhone with an iOS 26 runtime
xcrun simctl boot "<UDID>"
xcrun simctl bootstatus "<UDID>" -b
xcodebuild -project ios/AroomaNative.xcodeproj -scheme AroomaNative -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Arooma.app
```

Xcode must be installed with Command Line Tools selected and an iOS runtime installed (Xcode > Settings > Platforms).

## Commands (verified)

| Command | Use |
| --- | --- |
| `launchApp` | Start the app. `launchApp: { clearState: true }` wipes its data first. |
| `tapOn: "Text"` | Tap a visible element by its text. Also accepts `id:`. |
| `inputText: "value"` | Type into the focused field. Tap the field first. |
| `assertVisible: "Text"` | Fail if the text is not on screen. |
| `assertNotVisible: "Text"` | Fail if the text is on screen. |
| `scrollUntilVisible` | Scroll until an element appears. |
| `eraseText` | Clear the focused field. |
| `waitForAnimationToEnd` | Wait for motion to settle before reading values. |
| `back` | Press back. |
| `runFlow` | Run another flow file, optionally with a `when` condition. |
| `takeScreenshot: "name"` | Capture the screen as evidence. |
| `longPressOn: "Text"` | Used by `tuning-presets.yaml` in this repo. **Check** with `cheat_sheet`. |

Flow file format:

```yaml
appId: com.graymatter.arooma
---
- launchApp:
    clearState: true
- assertVisible: "Explore the Archive"
- tapOn: "Explore the Archive"
- assertVisible: "Add to my collection"
```

## MCP tools

| Tool | Purpose | Notes |
| --- | --- | --- |
| `list_devices` | Lists available emulators, iOS simulators and web targets. | Check your target appears before running. |
| `inspect_screen` | Compact JSON view hierarchy. | Call before selecting elements and after each UI change. |
| `take_screenshot` | Screenshot of the current device. | Use as evidence for every failure. |
| `run` | Runs flows. Exactly one of `yaml`, `files`, or `dir`. | `dir` accepts `include_tags` and `exclude_tags`. |
| `cheat_sheet` | Command and syntax reference. | Call before using anything unfamiliar. |
| `list_cloud_devices`, `run_on_cloud`, `get_cloud_run_status` | Maestro Cloud. | Needs `maestro login` or `MAESTRO_CLOUD_API_KEY`. Poll status every 60 s until `SUCCESS`, `ERROR`, `CANCELED` or `WARNING`. Sends flows off the machine. |
| `open_maestro_viewer` | URL of the Maestro Viewer. | |

The docs do not describe a tool that starts a simulator or emulator. Boot it yourself (see above).

## Troubleshooting

- **Element not found:** re-run `inspect_screen`. The label may differ from what is shown (for example combined accessibility labels), or the element is behind a sheet.
- **Tap lands on the wrong element:** the text matches more than one element. Narrow the selector.
- **Flow hangs on an animation:** add `waitForAnimationToEnd` before the step, or assert on a stable element.
- **App state leaks between runs:** start with `launchApp: { clearState: true }`.
- **`maestro` not found from an agent:** the agent's PATH may be minimal. Use the full path and set `JAVA_HOME`.
