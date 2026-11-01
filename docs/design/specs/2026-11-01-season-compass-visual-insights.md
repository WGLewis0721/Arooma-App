# Arooma: Season Compass visual Insights (owner-approved reference)

> Part of the [Arooma design map](../README.md). Follow the existing native implementation and reference-coverage rules.

> Owner picked the **Layton Season Compass phone mockup** shown on 2026-11-01 and instructed: "Make them all look like that." This is a native SwiftUI implementation specification for every fragrance's Insights sheet, not a request to rewrite collectible card fronts or backs. The image shared in chat is the visual authority; the native layout below should be compared to that screenshot on an iPhone before claiming a visually verified match.

## Reference coverage matrix

| Reference element | Native implementation | Acceptance / truth rule |
| --- | --- | --- |
| Warm bone/cream editorial panel, rounded corners, brass/copper ink | `InsightPanel` surface + palette-aware dark counterpart | All themes remain legible; no flat white or black |
| Thin editorial header "SEASON COMPASS" | `compassHeading` | Visible for every selected fragrance |
| Large fragrance name, small house and concentration | `identityAndCompass` | Dynamic, truncation-safe, no Layton hardcoding |
| Two jewel-ring medallions for season and occasion | `SeasonCompassDial` | Derived from `InsightEngine.season/occasion`; unknown stays unknown |
| Three elegant rounded note rows | `ingredientRow` | Top, Heart, Base dynamic, three illustrated glyphs plus +N; tap expands exact written names; VoiceOver lists all |
| Five short accord chips | Horizontal `accords` carousel | Actual derived accords only, any number (not an invented fixed five); detail is labelled *derived* |
| Closest owned fragrance mini-card | `recommendation` | Only shown when a real owned comparison passes the current similarity rule; tap opens preselected Compare |
| Possible layer mini-card | `recommendation` | Existing recorded layer takes precedence; otherwise a labelled compatible-accord suggestion; tap opens preselected Compare |
| Five-dot Collection Overlap | `overlap` | Existing note/accord similarity quantized into 5 ticks **as a relative suggestion**; no owned comparison shows `—`, never a made-up 4/5 |
| Remaining information without wall of text | `detailDisclosure` | Wears, wishlist and explanation remain reachable via one disclosure |
| Peek and expanded sheet detents | Existing `AtelierGallery.insightOverlay` | Small peek displays name + medallions; expanded scroll shows all sections, never overflow under tab bar |
| Existing share/compare/close control cluster | `toolbar` | Same live actions; sharing hidden for unapproved Fall proofs per commercial content gate |

### Visual finish criteria

- Compare on a 390pt iPhone against the supplied mockup and do not confuse CI compile success with actual visual fidelity.
- Hierarchy: card deck remains visible behind sheet; cream parchment/muted copper for light mode; rich plum/bronze in dark mode; one consistent radius, hairline separators, measured 8pt rhythm.
- Notes show isolated illustration-like ingredient symbols (from a local deterministic ingredient dictionary, with non-fabricated fallback), never arbitrary copied photographs or made-up notes. Text remains available on tap and in VoiceOver.
- Never display literal names, suggestion scores, product art, seasons or closest matches hardcoded from the Layton screenshot.
- Respect Reduce Motion, Dynamic Type, safe areas and VoiceOver. Expanded panel scroll must remain responsive with a one-finger gesture.
- No new backend, AI subscription, APIs, tracking, photo permissions, purchases, or user-data migrations.
- Source: `ios/AroomaNative/Insights.swift`; integration: `AtelierGallery.swift`. Preserve original note engine and owned/recorded history logic.

### Release gate

- [ ] Xcode native Debug and internal unsigned Release CI compile
- [ ] Docs checks pass
- [ ] Run with sample Layton: season suggestion and actual notes, not hardcoded screenshot content
- [ ] Run with missing notes: shows "Notes not recorded", no fake season or similarity
- [ ] Run with no owned cards: "No match yet", overlap `—`
- [ ] Run with an owned comparable fragrance: recommendation buttons open Compare with suggested selection
- [ ] Run with personal captured fragrance: UI remains useful without note metadata
- [ ] Test at compact/expanded detents, dark and light appearance and large text
- [ ] Real-device visual sign-off required before claiming exact fidelity

**No silent simplification:** This feature must retain information and access actions while replacing its presentation. The reference is the bar; a compiling replacement is not automatically design-approved.
