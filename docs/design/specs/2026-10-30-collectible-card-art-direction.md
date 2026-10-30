# Spec: Archive Foil fragrance collectible image standard

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). This is a **docs/creative-spec task**, not an authorization to implement an in-app collectible feature.

| | |
| --- | --- |
| Request | Analyze four Prada website stills, combine them with the owner's approved modern overframe trading-card style, and preserve composition, generation instructions and a checklist for all future AI-generated images |
| Restated | Give artists and GenAI agents one repeatable, coherent standard for a standalone **front/back collectible image pair** without changing Arooma's cabinet UI |
| Surface | Generated art assets; not regular cards, share image or app screens |
| Size | L: multiple art surfaces and explicit visual-rule exceptions |
| Author | ChatGPT, 2026-10-30 |
| Status | **In review**, standards committed for feedback; owner approval to ship or integrate not assumed |
| Governing docs read | [RULES_CARD.md](../RULES_CARD.md) Look/Boundaries/Verify; [README.md](../README.md) §§2-4,6; [packs/spec-writing.md](../packs/spec-writing.md); [packs/shelf-change.md](../packs/shelf-change.md); [brand/BRAND_BOARD.md](../brand/BRAND_BOARD.md) §§1-3,6; [PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md) §§2-6; [specs/TEMPLATE.md](TEMPLATE.md) |

## 1. Problem

A fragrance collector wants to make a two-sided Arooma keepsake for an owned bottle. Early image generations become cluttered with fantasy ocean effects, gold trim and unreadable microtext; later iterations look calmer but are not codified. Without shared rules, a new model will repeat the errors or mix Eau de Parfum imagery and notes with another concentration.

## 2. Evidence and context

- [Owner] The user explicitly rejected two busy holographic iterations and approved a quieter image with a dark navy bottle, low-key evening sea and a thin cool iridescent perimeter. They requested two separate faces, the bottle front and compact fragrance metadata on the back.
- [Owner] Four screenshots taken from Prada's actual product site show, separately, the Ocean EDP blue splash campaign, dark tactile ingredient stills, a ruby-gradient **Le Parfum** hero and another ingredient still with EDT text below it. They are mixed references, not one EDP brief.
- [3P] [Prada EDP page](https://www.prada.com/us/en/p/product/2A1157_2HEB_F0Z99_P_ML100) lists grapefruit essence, incense and vanilla bean accord; it describes AmberXtreme as an intensifier. [Prada Le Parfum page](https://www.prada.com/us/en/p/luna-rossa-ocean-le-parfum-50ml/2A1158_2HEF_F0Z99_P_ML050) lists lemon, saffron and oakwood. Do not transpose either one onto the other.
- [Repo] [BRAND_BOARD.md](../brand/BRAND_BOARD.md) §§1-3 defines paper/oat cabinet cards, neutral bottle artwork, no black/gold variant, and a fictional-house demo. This collectible concept requires a strictly separate art treatment.
- [Rec] Overframe grammar here means hero overlap **inside** the crop, continuous illustration across a thin inner line, restrained print material and a compact fact panel; it never means game UI or reproducing a specific trading-card design.
- [Assumption] The reference images remain in the user's chat and are **not copied into this public GitHub repository**. Written observation and live official URLs serve as durable references. Image and trademark usage rights remain unverified.

## 3. Goals, non-goals and budget

**Goals:** one recognizable bottle at first glance; quiet, premium, repeatable front and reverse; reference-verified product data; full-bleed but controllable overframe illusion; legible small-screen text; a checklist that another model can execute. The authoritative composition and instructions are in [../brand/COLLECTIBLE_CARD_ART_DIRECTION.md](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md).

**Non-goals / no-gos:** do not build image generation into Arooma, redecorate the cabinet, copy proprietary trading-card/IP elements, scrape and commit Prada campaign images, infer actual fragrance performance, authenticate bottles or claim a sponsorship. This task produces documentation, not images or runtime code.

**Appetite:** one documentation-only PR, minimal changes to map, pack and decision index. No new dependency, service, product schema or design tokens.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this request touches it |
| --- | --- |
| [RULES_CARD.md](../RULES_CARD.md), Look | Its Paper/Olive/Clay and no-glass rule applies to app UI; generated artwork receives a **bounded surface exception** only |
| [RULES_CARD.md](../RULES_CARD.md), Boundaries | The fictional demo stays unbranded; owners can use their own bottle images for a concept but rights for public distribution need review |
| [BRAND_BOARD.md](../brand/BRAND_BOARD.md), §§1-3 | The neutral shared shelf light remains unchanged; Archive Foil is not a new app palette |
| [BRAND_BOARD.md](../brand/BRAND_BOARD.md), §6 | The 4:5 shelf share graphic stays editorial paper; it is not replaced by the 59:86 collectible |
| [PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md), §§2-6 | Explicit options, scope, owners, acceptance tests and no silent exception |
| [../packs/collectible-image-generation.md](../packs/collectible-image-generation.md) | Brief router points future GenAI work to the complete standard |

**Exceptions needed (owner decides, do not assume):** **Owner-requested for creative concept assets only:** real Prada product reference and label; navy/foil material; color/type outside Warm Archive. **Not approved:** shipping third-party branded artwork, using official copyrighted stills without permission, making this the default in-app card, new data/network feature, changing core tokens. Every future use in the application needs a separate owner-reviewed scope/rights decision.

## 5. Options and the chosen concept

### Options considered

| Option | Idea in 2 to 3 lines | Pros | Cons |
| --- | --- | --- | --- |
| A. Full fantasy overframe | Saturated illustrated sea, luminous foil all over, baroque title panels | Recognizable “rare collectible” at a glance | The owner rejected it: clutter, generic AI look, weak bottle identity |
| B. Minimal campaign cutout | Large exact Prada bottle on nearly flat dark blue, slim title and no custom depth | Most faithful and quiet | No card-specific tactility; little overframe character |
| C. Archive Foil editorial collectible | Exact photographic hero against subdued ocean, a *single* inner-border overlap, thin cool diffraction, compact printed lower panel, quieter information reverse | Harmonizes Prada's art with card collectability | Requires disciplined copy and foil QA |

**Chosen:** C, matching the owner's latest approved direction. **Rejected:** A for gaudiness and B as too much a product ad rather than a collectible. No monsters, game stat blocks or fan-card marks.

### Breadboard of the chosen concept

- **Front:** compact title/EDP top; bottle large over dark sea middle; thin outlined lower band with concentration, **MASCULINE**, verified release year and fictional **ULTRA RARE**; Arooma microfooter. Crop ratio 59:86.
- **Reverse:** same trim and typography; title/concentration; official note map top/heart/base; a 22-30 word neutral description; optional sourced community ratings; tier and footer.
- **Connection:** front and back are two discrete matching files, not a collage; if shown in-app later, the flip behavior must be separately specified.
- **Compositional system:** exact normalized Y zones and spatial budget in [COLLECTIBLE_CARD_ART_DIRECTION.md](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md) §3. Print-light strategy and negative prompts in §§2,4.

### States

- **Empty input:** no photo? Ask for exact bottle, skip branded generation if identity cannot be grounded.
- **First run:** use owner-approved quiet card and copy manifest, never old ornamental iteration.
- **Loading:** generator state belongs to the calling tool; do not counterfeit a delivered file.
- **Error:** unreadable plaque, incorrect concentration or text hallucination is a reject and retry.
- **Overflow:** text exceeds bounds? Shorten copy or move the field to reverse, never shrink to illegible size.
- **Offline:** reusable templates and observations remain; source facts must be marked unchecked if not refreshed.
- **Low stock:** never infer liquid quantity from a photo. Original app level estimate is unrelated to collectible artwork.
- **Undo:** keep original photo and approved prior version so the human can revert.
- **Refused action:** if distribution rights or sensitive product attribution are unresolved, keep concept local.
 
## 6. Platform behavior

- **Widths/orientation:** exported art stays 59:86. Test rendered widths 375, 390 and 430 CSS px and a 360 px card preview; no clipped edge. Do not infer layouts from phone model.
- **Safari vs Home Screen:** this task changes no shipped UI; neither mode is affected. Future embedding must honor safe areas and landscape prompt.
- **Appearance:** standalone asset uses dark navy print material only. Cabinet remains Warm Archive light with specified unbuilt night theme.
- **Accessibility:** maintain text contrast, avoid color-only tier/sex classification, and keep selectable plain-text metadata outside any image if integrated later. VoiceOver needs alt equivalent on future embedded images; dynamic type cannot enlarge baked image text, hence metadata must remain accessible as DOM if shipped.
- **Input/haptics:** no gestures, haptics or new interactivity in the present docs-only task. Any future flip uses existing accessible card patterns rather than new unsupported motion.

## 7. Technical approach

- **Where it lives:** one governing design guide under `docs/design/brand/`, one short pack under `docs/design/packs/`, this dated spec, and links in design map, spec index and decision log.
- **Data/state:** no schema changes, no image upload to repo, no `index.html` changes. Nothing leaves the device via this task. Individual image tools may process owner-supplied photographs under their own terms.
- **Flags/rollout:** not applicable. Feature integration needs a new spec and an opt-in implementation plan.
- **Do not touch:** `BOTTLES`, `:root` tokens, share-image rendering, app icon, fiction-only demo and card interaction loops.
- **Dependencies:** none. Official URLs remain source citations, not runtime API calls.
- **Performance/privacy:** generated final assets may later be large; any integration must budget compressed size, image caching, local storage and personal-photo privacy first.

## 8. Risks, rabbit holes and open questions

| Item | Why it matters | Proposed default | Who decides |
| --- | --- | --- | --- |
| Actual Prada photography and trademark rights | Owner photo differs from licensed campaign assets | Use owner-supplied photo only for private creative concept; do not republish official campaign stills | Owner/legal review before shipping |
| Brand/variant mistakes | EDP/Le Parfum look close but facts differ | Pin exact concentration and source product code | Image agent, human QA |
| Foil overwhelms bottle | Main failure in first attempts | ≤10% area with diffractive highlights, thin border | Art reviewer |
| Date/community rating volatility | Numeric visuals go stale | Omit unless independently checked with source and as-of date | Content reviewer |
| UI integration | Conflicts with current Paper card and no-brand demo | Documentation only, separate later implementation spec | Owner |
| Font licensing | Proprietary logos/type may not be redistributable | Use permitted face and exact text overlay | Implementer |
| Prompt portability | Different image models interpret foil differently | Anchor to the composition and acceptance checklist, not model magic words | Art reviewer |

## 9. Verification and prototype plan

### Acceptance criteria

- Given the original EDP bottle photo, when rendered as an Archive Foil card, then its navy/black silhouette, exposed red spray feature and vertical red PRADA plaque remain recognizable and correct.
- Given conflicting Prada stills, when making an EDP back card, then TOP is grapefruit essence, HEART is incense, BASE is vanilla bean accord, without Le Parfum or EDT notes.
- Given a 360 px wide preview, when read on a phone, then title, EDP, classification, note labels, footer and any ratings remain readable and no corner is cropped.
- Given front and reverse exports, when placed at the same size, then corners, edge treatment, palette and footer anchor match.
- Given any earlier busy gold-frame output, when evaluated under §5 of the guide, then it fails and is not promoted as the reference standard.
- Given a new Arooma UI request, when agents read the router, then they follow the normal shelf pack unless an **explicit collectible-art** request calls for this pack.

### Checks

- Validate document map, relative links, agent budget and pack heading pointers with `npm run docs:check`.
- Run `npm test` if no existing CI exemption, and check no change to `index.html` or assets.
- Visual owner QA: bottle fidelity, typography at 360 px, pair cohesion, printed light response, negative-space share.
- **Owed on physical iPhone if shipped:** 375/390/430 px, Safari and standalone, text zoom, Reduce Motion, Increase Contrast, dark/light environment, safe areas and no overflow.
- **Not checked by docs-only task:** phone rendering, generated asset validity, trademark/license clearance.

### Prototype plan (when feel is the open question)

- **Must be real:** exact user bottle silhouette/photo and a proof at 59:86 read at phone size.
- **Can be faked:** foil gleam and light angle in static concepts; cannot fake product wording or brand facts.
- **Where:** review two separate full-resolution PNGs and 360 px previews, before any integration.
- **Questions for the tester:** Can you identify the exact bottle immediately? Does the foil distract? Can you read all the information?
- The prototype is disposable until a later implementation spec approves production assets.

## 10. Rollout, rollback and release

Docs-only branch and PR. No generated assets, app deployment or live feature activation. If disliked, close the PR or revert the documentation commit; nothing in the app changes. Owner approval is required before merging or applying this exception beyond concept images.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-30 | Document the owner's quietest Archive Foil style as a **collectible concept-only** visual standard, explicitly isolated from Warm Archive app cards; preserve Prada EDP vs EDT vs Le Parfum references as distinct | Owner direction, ChatGPT documentation | [../brand/COLLECTIBLE_CARD_ART_DIRECTION.md](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md), [../packs/collectible-image-generation.md](../packs/collectible-image-generation.md), [../DECISIONS.md](../DECISIONS.md) |
