#!/usr/bin/env bash
# Captures real iOS Simulator evidence for one build of Arooma.
#   ios/Tests/capture.sh <path/to/Arooma.app> <output-dir> <before|after>
# Screens are seeded through the app's own on-disk archive format (arooma-native-v1.json), so
# the same states are photographed for the baseline (main) build and for this branch.
# "after" additionally records the QA autoplay (real deck engine, synthetic finger curves)
# and the frame-pacing probe's console output. Simulator numbers are NOT device numbers.
set -uo pipefail
APP="${1:-}"; OUT="${2:-}"; LABEL="${3:-}"
BUNDLE=com.graymatter.arooma
mkdir -p "$OUT"
DEVICE=$(xcrun simctl list devices available -j | python3 -c '
import sys,json
d=json.load(sys.stdin)["devices"]
pref=["iPhone 17 Pro","iPhone 16 Pro","iPhone 17","iPhone 16"]
cands=[(k,v) for k,vs in d.items() for v in vs if "iPhone" in v["name"] and ("iOS-26" in k or "iOS 26" in k)]
for p in pref:
    for k,v in cands:
        if v["name"]==p: print(v["udid"]); sys.exit()
print(cands[0][1]["udid"] if cands else "")')
if [ -z "$DEVICE" ]; then echo "No iOS 26 iPhone simulator"; exit 0; fi
xcrun simctl boot "$DEVICE" 2>/dev/null || true
if [ "$APP" = "--preboot" ]; then echo "pre-booting $DEVICE"; exit 0; fi
perl -e 'alarm 720; exec @ARGV' xcrun simctl bootstatus "$DEVICE" -b || { echo "boot failed"; exit 0; }
xcrun simctl status_bar "$DEVICE" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 2>/dev/null || true
xcrun simctl uninstall "$DEVICE" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$DEVICE" "$APP"

seed() { # $1 = json mode: welcome|demo-coverflow|demo-stack|demo-fan|mine
  local container
  xcrun simctl launch "$DEVICE" "$BUNDLE" >/dev/null 2>&1; sleep 2
  xcrun simctl terminate "$DEVICE" "$BUNDLE" >/dev/null 2>&1
  container=$(xcrun simctl get_app_container "$DEVICE" "$BUNDLE" data)
  python3 - "$container/Documents/arooma-native-v1.json" "$1" <<'PY'
import json, sys, time
from pathlib import Path
path, mode = Path(sys.argv[1]), sys.argv[2]
now = time.time() - 978307200
base = dict(mode="Demo", theme="Obsidian Gold", appearance="Dark", layout="Cover Flow",
            selectedDemoID="dior", selectedMineID=None, selectedShelf="Autumn", rotationID=None,
            bottles=[], rotations=[], onboarded=True)
if mode == "welcome": base["onboarded"] = False
if mode == "demo-stack": base["layout"] = "Stack"
if mode == "demo-fan": base["layout"] = "Fan"
if mode.startswith("mine"):
    ids = [f"00000000-0000-4000-8000-00000000000{i}" for i in range(1, 6)]
    s1, s2 = "10000000-0000-4000-8000-000000000001", "10000000-0000-4000-8000-000000000002"
    def b(i, fid, shelf, wears=(), fav=False, rem=0.8):
        return dict(id=ids[i], fragranceID=fid, shelf=shelf, purchased=now - 9e6, volumeML=100,
                    remaining=rem, personalNotes="", authenticityNotes="", favorite=fav, wears=list(wears))
    w = lambda n, t, s: dict(id=f"20000000-0000-4000-8000-00000000000{n}", date=t, impression="", sessionID=s)
    base.update(mode="Mine", selectedMineID=ids[1], shelfNames={"Autumn": "Night Cabinet"},
        bottles=[b(0, "dior", "Autumn", [w(1, now - 3600, s1)], True),
                 b(1, "hawas", "Summer", [w(2, now - 3600, s1), w(3, now - 172800, s2)]),
                 b(2, "myslf", "Spring"), b(3, "prodigy", "Winter", rem=0.15),
                 b(4, "personal-QA", "Autumn")],
        wearSessions=[dict(id=s1, date=now - 3600, bottleIDs=[ids[0], ids[1]], note="Warm and spiced"),
                      dict(id=s2, date=now - 172800, bottleIDs=[ids[1]], note="")],
        customFragrances=[dict(id="personal-QA", house="My Collection", name="Oud Wood Sample",
                               concentration="Personal discovery", year="", top=[], heart=[], base=[],
                               shelf="Autumn", archival=False)],
        savedLayers=[dict(id="30000000-0000-4000-8000-000000000001", name="Evening layer",
                          bottleIDs=[ids[0], ids[1]], created=now - 86400)])
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(base))
PY
}

shot() { # $1 name, rest = launch args
  local name="$1"; shift
  xcrun simctl launch "$DEVICE" "$BUNDLE" "$@" >/dev/null 2>&1
  sleep 4.5
  xcrun simctl io "$DEVICE" screenshot "$OUT/$LABEL-$name.png" >/dev/null 2>&1 && echo "captured $LABEL-$name"
  xcrun simctl terminate "$DEVICE" "$BUNDLE" >/dev/null 2>&1
}

seed welcome;         shot 01-welcome
seed demo-coverflow;  shot 02-coverflow
seed demo-stack;      shot 03-stack
seed demo-fan;        shot 04-fan
seed mine;            shot 05-mine-gallery
if [ "$LABEL" = "after" ]; then
  seed mine; shot 06-shelves -AroomaQATab shelves
  seed mine; shot 07-today -AroomaQATab journal
  seed demo-coverflow; shot 08-inspector -AroomaQAInspect YES
  # Interaction recording: real engine, scripted finger, plus the frame-pacing probe log.
  seed mine
  xcrun simctl io "$DEVICE" recordVideo --codec=h264 --force "$OUT/after-autoplay.mp4" &
  REC=$!
  sleep 1.5
  xcrun simctl launch --terminate-running-process --stdout="$OUT/after-frame-pacing.log" --stderr="$OUT/after-stderr.log" \
    "$DEVICE" "$BUNDLE" -AroomaAutoplay YES -AroomaFramePacing YES >/dev/null 2>&1
  sleep 30
  kill -INT "$REC" 2>/dev/null; wait "$REC" 2>/dev/null
  xcrun simctl terminate "$DEVICE" "$BUNDLE" >/dev/null 2>&1
  grep AroomaFramePacing "$OUT/after-frame-pacing.log" || echo "no frame pacing lines captured"
fi
ls -la "$OUT"
