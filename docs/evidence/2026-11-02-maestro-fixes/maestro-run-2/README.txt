Run 41339765579 (artifact 13097118455), head 46b7738: no flow ran.
Lint, build and simulator install passed. "Run Maestro flows" ended after 3 min 13 s (19:10:40 to 19:13:53 UTC):

  iOS driver not ready in time, consider increasing timeout by configuring MAESTRO_DRIVER_STARTUP_TIMEOUT env variable
  xcuitest.installer.LocalXCTestInstaller$IOSDriverTimeoutException
      at xcuitest.installer.LocalXCTestInstaller.start(LocalXCTestInstaller.kt:104)

The simulator took 4 min 42 s to boot, with "Waiting on System App" in the log. The artifact holds only the XCTest runner log,
final-screen.png and final-hierarchy.txt: no junit.xml and no flow output. This is a runner start-up timeout, not a flow or app
result. It was re-dispatched once (run 41341165470, run 3).
