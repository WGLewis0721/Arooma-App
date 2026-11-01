# Maestro UI flows (opt-in)

Flows for [Maestro](https://maestro.dev) that drive the native app on an iOS Simulator.
They are **not** a pull-request gate. Run them from the **Maestro iOS** workflow (Actions → *Maestro iOS* → Run workflow), or locally:

```bash
# Debug build installed on a booted iPhone simulator (iOS 26)
maestro test .maestro/
```

Requirements: macOS, Xcode 26 with an iOS 26 simulator, Java 17+ and the Maestro CLI.
Flows use visible text, so they do not depend on code identifiers.
