# Spec: <short title>

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). Save as `docs/design/specs/YYYY-MM-DD-<slug>.md`.

| | |
| --- | --- |
| Request | The owner's request in their words |
| Restated | One sentence: who it is for, on which surface |
| Surface | Shelf, card, sheet, test timer, share image, icon, widget, or a device (iPhone, iPad) |
| Size | S, M or L (see the protocol) |
| Author | Person or tool, and date |
| Status | Draft, In review, Approved, Superseded |
| Governing docs read | Paths and sections |

## 1. Problem

One specific story: who is in what situation, what they try, and why the current behavior fails them. No solution here.

## 2. Evidence and context

What is known: current behavior, screenshots or code paths, test findings, related decisions. Tag claims `[Repo]`, `[Apple]`, `[3P]`, `[Assumption]`.

## 3. Goals, non-goals and budget

- **Goals:** what must be true when this is done.
- **Non-goals / no-gos:** what this deliberately does not do, to keep it small.
- **Appetite:** how much effort this is worth. The solution must fit it.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this request touches it |
| --- | --- |
| | |

**Exceptions needed (owner decides, do not assume):** anything that would add a color, font or decorative style, put glass or blur on a card, use a real brand, add a backend or network call, or claim authenticity or a scent match. Write "None" if none.

## 5. Options and the chosen concept

### Options considered
For size L give at least three distinct directions (different structure or interaction, not different colors). For size M give two.

| Option | Idea in 2 to 3 lines | Pros | Cons |
| --- | --- | --- | --- |
| A | | | |
| B | | | |
| C | | | |

**Chosen:** which, and why. **Rejected:** and why, so nobody reopens it by accident.

### Breadboard of the chosen concept
Places (screens, sheets, states), the affordances in each, and the connections between them. Describe layout in words or a plain sketch. Use tokens and existing patterns for look; do not specify pixels the tokens already decide.

### States
Empty, first run, loading, error, overflow, offline, low stock, undo, refused action. One line each.

## 6. Platform behavior

- **Widths and orientation:** 375, 390, 430 phones, and the framed device on wider windows. The landscape prompt. Layout from width and aspect ratio, never device model.
- **Install mode:** Safari tab versus Home Screen (standalone). Safe areas per side.
- **Appearance:** light today; the night palette is specified, not built. Surfaces and text use tokens.
- **Accessibility:** VoiceOver labels and order; 44 pt targets; Dynamic Type or text zoom; Reduce Motion, Reduce Transparency, Increase Contrast; status never by color alone.
- **Input:** touch, keyboard, pointer. The tap and keyboard alternative for every drag.
- **Haptics and motion:** which existing moments are used (settle, wear, completed action); nothing new unless listed in section 4.

## 7. Technical approach

- **Where it lives:** the functions and sections of `index.html`, or the file.
- **Data and state:** `BOTTLES` fields used or added; any storage key. State if anything leaves the device (nothing, today).
- **Flags and rollout:** is a flag needed, what is the default.
- **Do not touch:** confirm the Boundaries in [../RULES_CARD.md](../RULES_CARD.md) hold.
- **Dependencies:** none, or each with its license and why. The page is one self-contained file.
- **Performance and privacy:** anything that blurs, animates or stores data.

## 8. Risks, rabbit holes and open questions

| Item | Why it matters | Proposed default | Who decides |
| --- | --- | --- | --- |
| | | | |

## 9. Verification and prototype plan

### Acceptance criteria
Observable statements: "Given ..., when ..., then ...". No "code exists" criteria.

### Checks
- `npm run docs:check` and `npm test` ([../RULES_CARD.md](../RULES_CARD.md), Verify).
- Browser: widths, Reduce Motion, mouse and touch, no horizontal scroll.
- Owed on a physical iPhone (list them): Home Screen install, status bar, launch image, drag feel, haptics, share sheet, offline.

### Prototype plan (when feel is the open question)
- **What must be real:**
- **What can be faked:**
- **Where it will be used:**
- **Questions for the tester:** Do you know how to do this? Is it easy? How can we make it better?
- The prototype is disposable. The real version is written afterward.

## 10. Rollout, rollback and release

Branch and review. Flag default. How to revert. Release authority stays with the owner; this spec is not approval to merge or ship.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| | | | |
