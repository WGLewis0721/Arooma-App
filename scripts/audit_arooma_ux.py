#!/usr/bin/env python3
"""Static half of the native Arooma UX audit; Maestro supplies interaction evidence.

Never report visual or device behavior as proven by matching source text.
"""
from __future__ import annotations
import argparse
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
def source(name: str) -> str:
    return (ROOT / "ios" / "AroomaNative" / name).read_text()

def record(num: int, signal: str, status: str, evidence: str, laws: list[str]) -> dict:
    return dict(number=num, signal=signal, status=status, evidence=evidence, laws=laws)

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=pathlib.Path)
    args = parser.parse_args()
    commercial = source("Commercial.swift")
    search = source("Search.swift")
    app = source("AroomaApp.swift")
    capture = source("Capture.swift")
    sections = source("AtelierSections.swift")
    store = source("CollectionStore.swift")
    artwork = source("Artwork.swift")
    principles = (ROOT / "docs/design/FOUNDATIONAL_UX_PRINCIPLES.md").read_text()
    required_laws = ["Hick's Law", "Jakob's Law", "Fitts's Law", "Gestalt", "Miller",
                     "Tesler", "Doherty", "Aesthetic–Usability", "Von Restorff", "Goal-Gradient"]
    missing = [law for law in required_laws if law not in principles]
    assert not missing, "Foundational UX principles file missing laws: " + repr(missing)

    records = [
        record(1, "Purple gradients", "manual", "Theme colors require approved Arooma visual review, not a purple-color ban.", ["Unity","Aesthetic–Usability"]),
        record(2, "Excessive padding", "maestro+manual", "Inspect Explore/Mine first-screen screenshots and safe-area edges.", ["Fitts","Balance"]),
        record(3, "Keyboard covers input", "maestro", "ux-audit-keyboard-empty-state captures Search with keyboard open; Capture keyboard is separate.", ["Jakob","Fitts"]),
        record(4, "Buttons too small", "source", "Quick tool minHeight>=44: " + str(".frame(maxWidth: .infinity, minHeight: 44)" in app) +
               "; Capture minHeight 32/36 removed: " + str(not re.search(r"minHeight: (?:32|36)\b", capture)), ["Fitts"]),
        record(5, "No caching", "source", "Existing decoded asset NSCache and card photo NSCache: " +
               str("NSCache" in artwork and "NSCache" in commercial), ["Doherty"]),
        record(6, "Text too small", "source", "Search badge uses Dynamic Type caption2: " +
               str(".font(.caption2.weight(.bold)).tracking(0.4)" in search), ["Scale"]),
        record(7, "Spinners everywhere", "maestro+manual", "Loading patterns must be reviewed by task; contextual photo processing indicator exists.", ["Doherty"]),
        record(8, "Emojis", "manual", "Symbols are not a defect by themselves; inspect navigational clarity and labels.", ["Gestalt"]),
        record(9, "Double-tap submits twice", "source+maestro", "Direct guard present: " +
               str("guard direct == nil, isSimpleName else" in capture) +
               "; scan guard present: " + str("guard committed == nil else" in capture) +
               ". Still requires stress test.", ["State truth"]),
        record(10, "Blank new-user screen", "maestro", "Welcome/Explore and empty Mine captured by tagged Maestro screenshots.", ["Jakob","Hierarchy"]),
        record(11, "Text scaling issues", "manual", "Dynamic Type and VoiceOver sizing still need simulator accessibility size sweeps.", ["Scale"]),
        record(12, "Dark/light issues", "maestro+manual", "Appearance flow smoke tests navigation, not contrast across every theme.", ["Unity","Contrast"]),
        record(13, "Raw error text", "source", "Commercial user-facing raw localizedDescription remains: " +
               str(bool(re.search(r"(?:status|commerce.status)\s*=\s*[^\n]*localizedDescription", commercial))), ["State truth","Aesthetic–Usability"]),
        record(14, "No tap animations", "maestro+device", "Transitions and haptics need visual/hands-on proof; source has springs.", ["Doherty"]),
        record(15, "User preferences wiped", "source+maestro", "Atomic persisted collection and appearance state: " +
               str("options: .atomic" in store and "appearance = saved.appearance" in store), ["Tesler","Zeigarnik"]),
    ]
    violations = []
    if ".frame(maxWidth: .infinity, minHeight: 44)" not in app:
        violations.append("Main tool button under accessible size")
    if re.search(r"minHeight: (?:32|36)\b", capture):
        violations.append("Capture has explicitly undersized action")
    if ".font(.caption2.weight(.bold)).tracking(0.4)" not in search:
        violations.append("Search badge lacks scalable type")
    if re.search(r"(?:status|commerce.status)\s*=\s*[^\n]*localizedDescription", commercial):
        violations.append("Raw errors exposed in commercial UI")
    report = dict(
        baseline="main:b5ec118ad7cdbc9fa111bcac576b272043173627",
        evidence="source-inspection only; not a device test",
        principles=required_laws,
        screenshot_signals=records,
        static_violations=violations,
        runtime_evidence="Use Maestro-results JUnit, screenshots, and hierarchy to verify runtime behaviors",
    )
    output = json.dumps(report, indent=2) + "\n"
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(output)
    print("Arooma static UX audit: " + str(len(records)) + " screenshot checks and " +
          str(len(required_laws)) + " law groups; " + str(len(violations)) + " static violations.")
    for v in violations:
        print("FAIL:", v)
    raise SystemExit(1 if violations else 0)

if __name__ == "__main__":
    main()
