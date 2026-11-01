# Arooma | Foundational UX and Web Design Principles

> Summary: Arooma's seven fundamentals and ten UX laws translated into measurable, native iOS card and ownership interactions.

> Part of the Arooma design brain. Start at [README.md](README.md) for the design router and authoritative task packs.

**Status:** cross-product UX standard for the native SwiftUI iOS app. This guidance is not permission to alter approved collectible art, add features, revive the retired PWA, or change storage or release flows.

**Provenance:** adapted from [Studigo's foundational UX policy](https://github.com/WGLewis0721/Studigo-ai/blob/main/docs/ux/FOUNDATIONAL_UX_PRINCIPLES.md), using [Jon Yablonski's Laws of UX](https://lawsofux.com/) and [the seven fundamentals](https://www.concretecms.com/about/blog/web-design/7-fundamentals-of-web-design).

## Principle: the fragrance stays the hero

UX principles are the structure; [Arooma's approved brand board](brand/BRAND_BOARD.md), approved photographic masters, [native direction](../../NATIVE_ATELIER_FINAL.md), and surface-specific implementation specs are the expression. Preserve the premium collectible-card experience, independent Demo/Mine data and real ownership records. Laws are task-dependent heuristics, not guaranteed numerical outcomes. Accessibility, copyright/provenance rules and data truth take priority.

## Seven design fundamentals

| Fundamental | Arooma operating standard | Review |
| --- | --- | --- |
| **Unity** | Cover Flow, Stack, Fan, search, shelves and ownership feel like the same private archive | Consistent type roles, gestures, content controls and state semantics |
| **Balance** | The selected photographic card dominates; controls support it and do not cover it | Card remains the visual focus in every layout |
| **Hierarchy** | Bottle → intended action (inspect, wear, add, find) → details, with one obvious next step | Five-second test and one visually dominant action |
| **Contrast** | Text, card information, errors and controls remain readable in light/dark and accessibility appearances | Contrast/focus and Dynamic Type checks |
| **Emphasis** | Selection and confirmed action are clear without constant badges, glows or competing animated objects | Focused-card and feedback review |
| **Scale** | Artwork edges remain intact; legible ownership information and accessible controls fit device safe areas | 44 pt iOS targets; no clipping with larger text |
| **Repetition** | Layouts transform the same card objects; reuse inspection, action and sheet patterns | State persists while layouts change |

## Laws of UX applied to Arooma

| Law | Product behavior | Acceptance evidence |
| --- | --- | --- |
| **Hick's Law / selective attention** | Keep the focused card and its next action clear; reveal secondary details contextually, without hiding provenance or safety | Count first-screen choices and taps to Wear, Search, Add and inspect |
| **Jakob's Law** | Native sheets, back navigation, collection switch, search and editing behave like familiar iOS controls | User completes basic flows without novel gesture instructions |
| **Fitts's Law** | Selection, swiping, flipping and high-frequency actions get reachable, stable hit areas; 44 pt target expectation on iOS | Inspect hit boxes, safe areas and card/control overlaps |
| **Gestalt: proximity, similarity, common region** | House, fragrance, concentration, notes and owner information have coherent visual groups | Reading order matches visual relationship |
| **Miller / chunking / working memory** | Bottle inspection reveals information in manageable layers; users do not have to memorize fragrance names while making a collection action | Short task path and persistent context across layouts |
| **Tesler's Law / Occam's Razor** | Remove chrome, not real Demo/Mine separation, ownership attributes, source provenance, backup or deletion safeguards | Data and privacy invariants survive UI changes |
| **Doherty Threshold** | Finger tracking and selection feedback feel immediate; background work shows real processing states, no fabricated success | Check interactive response on an actual device |
| **Aesthetic–Usability Effect** | Elegant visuals, foil and haptics support understanding; decoration never masks broken search or unreadable details | All essential tasks succeed with Reduce Motion |
| **Von Restorff / serial position** | The selected card and primary action are identifiable without making every card or action prominent | Visual dominance audit |
| **Goal-Gradient / Zeigarnik / Peak–End** | Saved wear history and unfinished edits restore truthfully; successful actions have brief feedback, not pressure loops | Verify stored records before and after app restart |

## Native iOS acceptance checks

1. The **same bottle stays selected** when changing Cover Flow, Stack and Fan. Gestures track touch smoothly; no layout may obscure the selected object.
2. Users can enter a fragrance, search, inspect a card and log a wear using a direct, discoverable action path. Review number of interactions, not just screen appearance.
3. Every gesture-only action has a visible/accessibility alternative where appropriate, with VoiceOver, Dynamic Type, Reduce Motion and Increase Contrast tested.
4. Keep **Demo** and **Mine** separate; never claim estimated remaining volume, notes, authenticity or AI-generated catalog information is verified when it is not.
5. Do not change original card pixels or commercialize third-party artwork without provenance/rights review. See [third-party content policy](brand/THIRD_PARTY_CONTENT_POLICY.md).
6. Test current shipping iPhone layouts first, plus any supported iPad sizes, narrow/landscape conditions, safe areas, light/dark, large text, offline, empty, error and restore states. Native-specific guidance is in [Arooma iOS guide](platforms/AROOMA_IOS_DESIGN_GUIDE.md).
7. No invented themes, control systems, backend, account or analytics. File exceptions under the normal [spec protocol](PLAN_SPEC_PROTOCOL.md) instead of silently bypassing governing design rules.

## Review sequence

**Real user task → content and hierarchy → applicable law → approved native Arooma patterns → interaction fidelity → accessibility and on-device evidence.** Cite laws as verifiable design decisions, not decorative vocabulary.
