---
name: maestro-ui-testing
description: Audit and test mobile app user flows with Maestro (maestro.dev). Use whenever asked to test, verify, audit, regression-check or reproduce a bug in a native iPhone or Android app's UI or user journey, to check that a button, screen, form or onboarding path works, or to automate a flow on an iOS Simulator or Android emulator. Drives the app with YAML flows through the Maestro CLI or its MCP server (inspect_screen, run, take_screenshot). Not for unit tests, backend tests or plain web-browser testing.
---

# Maestro UI testing and flow audits

Maestro runs real user journeys on a simulator or emulator. Flows are short YAML files that tap, type and assert on visible text. Use it to prove that a flow works, or to show exactly where it breaks, with screenshots as evidence.

This procedure is tool-neutral. If your agent has no skill support, read it as a plain checklist.

## 1. Check the environment first

- **macOS, Xcode and a booted iOS simulator** are needed for iOS. Check with `xcrun simctl list devices booted`.
- **The app must be installed** on that simulator. Maestro does not install it for you. Build a Debug app with `xcodebuild` and install it with `xcrun simctl install booted <App.app>`.
- **Java 17+** (`java -version`). The Maestro CLI needs it.
- **Maestro CLI:** `maestro --version`. If it is missing, install it from the Maestro docs and verify the command before relying on it.
- Stop and report if any of these are missing. Do not guess results.

## 1a. No Mac? Run the flows from the repo on GitHub's macOS runner

If the owner has no Mac available, the **Maestro iOS** workflow (`.github/workflows/maestro-ios.yml`) does the same job on a GitHub `macos-26` runner with Xcode and an iOS 26 simulator:

1. Push the branch to GitHub.
2. Start the workflow: GitHub → Actions → **Maestro iOS** → **Run workflow** → pick the branch. Optional: `include_tags` / `exclude_tags` to run a subset.
3. The run checks flow syntax, builds the Debug app, boots an iPhone simulator, installs the app, runs `maestro test .maestro/`, and always uploads the **Maestro-results** artifact: `junit.xml`, per-run screenshots and logs in `run/`, `final-hierarchy.txt` and `final-screen.png`.
4. Read the JUnit file for pass/fail per flow. Open the screenshots and hierarchy to see the screen that failed.

What this proves: the flows run on a real iOS 26 simulator with the current code. What it does not prove: anything that needs a physical iPhone (camera, haptics, real tilt, real touch feel, real performance). Say so in the report.

Do not use Maestro Cloud for owner data: `maestro cloud` and `run_on_cloud` upload the app and flows off the machine.

## 2. Pick a driver

- **MCP (preferred for exploring and debugging, needs a Mac):** start the server with `maestro mcp`. The tools it exposes in Maestro CLI 2.12.0 are `list_devices`, `inspect_screen`, `take_screenshot`, `run` (inline `yaml`, specific `files`, or a `dir` with optional `include_tags`/`exclude_tags`), `cheat_sheet`, `open_maestro_viewer`, and the cloud tools. Some tool names in older notes (`launch_app`, `tap_on`, `run_flow`) do not exist in this version: check the live list before relying on a name.
- **CLI (preferred for repeatable runs, also works from the GitHub workflow):** `maestro test <file.yaml>` or `maestro test <folder>/`. Add `--format JUNIT --output report.xml` for a report and `--include-tags`/`--exclude-tags` to choose flows. `maestro check-syntax <file>` lints a flow without a device.
- **Maestro Cloud** (`run_on_cloud`, `maestro cloud`) sends your app and flows off the machine. Use it only when the owner has asked for it.
- Full setup commands and the MCP config are in [reference.md](reference.md).

## 3. Run the audit loop

1. **Write down the journey as user goals.** Example: "first launch → explore → add a bottle to the Wishlist". List the happy path first, then the failure paths: cancel, back, empty state, a required field left empty, and a rotated or relaunched app.
2. **Look before you write selectors.** Call `inspect_screen` (or the CLI equivalent) on each screen. Select by the text the user sees. Re-inspect after every navigation or sheet, because the hierarchy changes.
3. **Write one flow per journey.** Start with `appId`, then `---`, then the steps. Begin with `launchApp` with `clearState: true` so every run is repeatable. End each meaningful step with an `assertVisible` so a failure names the step that broke.
4. **Run one flow before running the folder.** Fix selector and timing problems there first.
5. **On a failure:** read the error, call `take_screenshot`, call `inspect_screen`, and confirm whether the app is wrong or the flow is wrong. Fix the flow only if the app is correct.
6. **Re-run the full set** after any fix and report the final state.

## 4. Writing reliable flows

- Prefer visible text (`tapOn: "Add to my collection"`). Use `id:` selectors only when text is ambiguous.
- If several elements share a label (for example two sheets with a "Done" button), narrow the selector rather than guessing which one a tap will hit.
- Use `assertVisible` after each action that changes the screen. Use `assertNotVisible` to prove something is gone.
- Use `inputText` after a `tapOn` that focuses a field.
- Use `waitForAnimationToEnd` before reading values during transitions. Screens with continuously animating content may never settle, so keep the step count small and allow for retries.
- Keep each flow to one journey. Use `runFlow` to share a setup flow (for example, reaching the main screen).
- If a command is unfamiliar, call `cheat_sheet` rather than inventing syntax.

## 5. Reporting results

Report only what actually ran. For each flow give:

- **Status:** pass, fail, or not run, with the reason for "not run".
- **Device and build:** simulator model, iOS version, and the app build used.
- **Steps covered** and the **first failing step**, with expected and observed behaviour.
- **Evidence:** screenshot paths and the relevant `inspect_screen` excerpt.
- **Gaps:** journeys not covered, and anything that needs a physical device (Maestro runs on simulators and emulators; haptics, camera and real motion sensors need a real iPhone).

Never claim a flow passed on a device that did not run it.

## 6. Project notes (Arooma)

- Bundle identifier: `com.graymatter.arooma`. Use it as `appId`.
- Existing flows live in `.maestro/` (smoke, Quick Add to Wishlist, tuning panel). The manual **Maestro iOS** GitHub workflow runs them on an iOS 26 simulator.
- The owner-only tuning panel (long-press **Version** in View & Style) exists only in Debug and TestFlight builds. Flows that use it must run against a Debug build.
- The welcome screen and the foil/shimmer effects animate continuously. Expect slower assertions there.
- Arooma is local-first with no accounts. Flows should start with `clearState: true`, and nothing needs to be signed in.
