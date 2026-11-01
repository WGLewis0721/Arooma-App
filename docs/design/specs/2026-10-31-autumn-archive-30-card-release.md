# Spec: Autumn Archive, 30 fragrance cards in the next Arooma native build

> Part of the [Arooma design brain](../README.md). Follow [the plan protocol](../PLAN_SPEC_PROTOCOL.md). This spec is an implementation and production plan, not a statement that the 30 artworks are finished or legally approved.

| | |
| --- | --- |
| Request | Design the curated Top 30 men's fall fragrances as MYSLF-quality collectible cards, store them, make them accessible to Arooma, and show them in the next native build. |
| Restated | An Arooma iPhone user browses 30 finished, accurate, illustrated fall-fragrance cards in an obvious seasonal collection, even offline. |
| Surface | Native iOS 26 Cards tab, collectible previews, browse/inspect, artwork asset pipeline, TestFlight |
| Size | L |
| Author | ChatGPT, 2026-10-31 |
| Status | In review: 30 draft briefs and an implemented native gallery hook; no new card art or TestFlight delivery |
| Governing docs read | [Brand Board](../brand/BRAND_BOARD.md), [Archive Foil art direction](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md), [Third-party content policy](../brand/THIRD_PARTY_CONTENT_POLICY.md), native `Artwork.swift`, `Commercial.swift`, `Models.swift`, `codemagic.yaml`, `AGENTS.md` |

## 1. Problem

The user has demonstrated that a single well-prompted, professionally rendered MYSLF card can be much better than asking a collector to manually transform their photo with basic filters. Arooma has only a handful of hardcoded approved-design image pairs and no seasonal card-library delivery system. The owner wants the exact 30 curated fall products from the conversation represented in a coherent, polished and discoverable native collection.

## 2. Evidence and context

- [Repo] `ApprovedArtwork.image(for:side:)` in `ios/AroomaNative/Artwork.swift` loads hardcoded, bundled PNG diptychs and caches images.
- [Repo] `MyCardsScreen` in `ios/AroomaNative/Commercial.swift` distinguishes created digital cards and purchased/library cards, but its Discover section is hidden while the commercial release flags are off. No seasonal browsing surface currently exists.
- [Repo] The native app is iOS 26 SwiftUI. `codemagic.yaml` has a manually run `arooma-testflight` signed-upload workflow.
- [Repo] `assets/collectibles/seasons/fall-2026/catalog.json` is the **production seed for the owner's 30 selected fragrances**, not a validated fact catalog and not an approved asset registry.
- [Rec] One successful generated MYSLF image demonstrates attainable quality; it does not establish uniform output quality or product accuracy across 30 automatic generations.
- [Rec] Check official product descriptions for exact variants and notes before generating labels. Do not copy product campaign images or marketing prose into the shipping app.

## 3. Goals, non-goals and budget

**Goals**
1. Create 30 separately art-directed, 59:86 complete card fronts at or above the MYSLF reference quality.
2. Preserve the visually distinctive real product: silhouette, cap, glass shape, colors and packaging. Never invent hidden or unsupported product details.
3. Use a reusable prompt and asset-production pipeline with per-card review, allowing regeneration without rebuilding the app.
4. Ship an **Autumn Archive** browse section in the **Cards** tab, separate from My Cards and My Bottles. Browse does not imply ownership.
5. Load only approved, in-bundle images, offline, with cached thumbnails, full-screen viewing, existing foil/motion behavior and card-share controls.
6. Allow later scaling to downloadable seasons without creating infrastructure now.

**Non-goals**
- No AI card generation on customer devices; no customer-hosted prompt editor, filter overhaul, backend, ads or IAP changes.
- No pretense that the brand issued collectible cards or that previewing means owning a bottle/card.
- No buying, randomized packs, subscription gating or access changes until rights, transactions and entitlements are approved.
- No 30-image cut-and-paste of one generic layout with just a renamed bottle.

**Appetite:** One focused first season of 30 independent images, QA, catalog integration, TestFlight build. Prioritize a polished curated release over an unreviewed high-volume catalog.

## 4. Rules and exceptions

| Governing rule | Application |
| --- | --- |
| `brand/COLLECTIBLE_CARD_ART_DIRECTION.md` sections 1-2 | Authentic single bottle, name/variant/concentration, photo-like scene, top-note label only if verified, subtle thin iridescent frame, 59:86 artwork. Default back is a readable 3-strip note map, not randomized rarity. |
| `brand/BRAND_BOARD.md` V2 override | Existing gallery, card materials, native animation, themes and Liquid Glass control separation remain intact. |
| `brand/THIRD_PARTY_CONTENT_POLICY.md` | Official product imagery is reference-only until cleared for redistribution; independently generated scenes still require per-asset trade dress/IP review. No commercial sales flags flipped. |
| `AGENTS.md` | Native iOS only, no PWA changes. Do not bypass existing CI or TestFlight signing gates. |

**Exceptions needed:** Actual recognizable commercial bottle representations, house names and shareable collectible art require per-asset legal review under the existing policy. No blanket legal clearance is assumed. No new backend is proposed.

## 5. Options and chosen concept

| Option | Approach | Pros | Cons |
| --- | --- | --- | --- |
| A | Bundle 30 optimized approved images and 30 metadata records in the native app | Works offline, simple, reliable, no hosting, ships on next TestFlight | Requires a new build to replace artwork |
| B | Host 30 images in Cloudflare R2 with a manifest | Add cards without a build, scales to 1,000+ | Needs remote URL/data integrity policy, cache logic, and offline fallbacks |
| C | Generate bespoke artwork after each user opens a product | Infinite catalog coverage | Cloud API expense, generation latency, packaging errors, rights and purchase complexity |

**Chosen: A for Autumn Archive.** Its expected optimized size is only tens of MB. Future seasons can adopt option B once the catalog and rights model are stable.

### Design and generation contract

- Master reference: the attached YSL MYSLF Arooma collectible example, plus the repo's locked Dior Archive Foil v3 art direction.
- Create a **product-specific brief** from `assets/collectibles/seasons/fall-2026/catalog.json`. Each includes the fragrance identity, verified concentration, allowed reference photograph(s), correct bottle silhouette, verified notes, and unique scene motif.
- Build a reusable master image-generation prompt: *single complete 59:86 portrait card, all four edges visible; original cinematic luxury still-life; authentic bottle identity as the hero; verified title and concentration; visually grounded materials/notes; restrained etched foil frame; legible Arooma footer; no rarity, game stats, extra bottles, human hands, app UI or fabricated brand copy.*
- Keep reference photography outside generated or shipped assets unless rights are documented. Prompt-only brand naming does not guarantee fidelity. If the product packaging cannot be reproduced, use a licensed product source or reject that card.
- Generate a **6-card calibration batch** spanning tobacco, gourmands, iris, leather, citrus/woods and a modern designer fragrance. Verify the image quality before generating the remaining 24.
- For each card use 2-4 variants as a planning allowance, not an automatic acceptance rate. Review the winner at full resolution. Manually correct brand text/typesetting from verified data when needed. Re-generate when packaging is wrong.
- Produce front masters at 1180 × 1720 PNG and app derivatives at the same 59:86 ratio as high-quality JPEG/HEIC if adequately supported by the target. **Do not substitute generic filters for final art.**
- **Backs:** Use one native, reusable, brand-neutral back renderer fed by verified top/heart/base facts. If such facts are absent, show a truthful minimal record; do not invent notes. This avoids 30 additional bespoke images without degrading front quality.
- Save approved human-readable source briefs, prompt version, generation model/version, output checksum, attribution/provenance and rights review result.

### Breadboard

**Cards tab**: "My Cards" | "Autumn Archive" (and "Discover" only when commercial offers are enabled). Autumn Archive is browse-only and does not automatically modify owned bottles/cards.

**Autumn Archive**: editorial heading, 30 visually rich full-card thumbnails in a responsive two-column grid. Tap a card to inspect the finished art. Search by house or fragrance. No "Buy" control; no fake rarity.

**Inspector**: full-size front, tap to flip to verified note map, existing tilt-driven highlights, safe-area-aware share button. Clearly identify as an independent Arooma artist edition.

**States**: 30 vetted assets -> visible; no vetted assets -> release gate prevents promoting the incomplete season; one corrupt/missing image -> CI rejects the bundle; offline -> all cards load; reduced motion -> still image; no ownership -> browsing remains separate.

## 6. Platform behavior

Native iOS 26 only. Support 375/390/430pt phone widths; 59:86 card aspect and fit within safe areas. Adapt grid to Dynamic Type. VoiceOver reads rank, house and fragrance, with an inspect action. Tap/keyboard alternatives to gestures; 44pt targets for controls. Honor Reduce Motion and Reduce Transparency. Images are locally decoded and cached off the live gesture path; avoid 30 simultaneous full-resolution decodes.

## 7. Technical implementation

**Repository artifacts**
- `assets/collectibles/seasons/fall-2026/catalog.json`: authoritative 30-entry seed. Draft statuses cannot be treated as shipping approvals.
- `assets/collectibles/seasons/fall-2026/masters/<id>-front.png`: lossless production artwork, archived in Git or Git LFS if necessary, **not included in app bundle**.
- `assets/collectibles/seasons/fall-2026/approved/<id>-front.jpg`: reviewed and optimized native delivery assets.
- `assets/collectibles/seasons/fall-2026/approved/<id>-provenance.json`: licensing/attribution evidence; do not publish private license documents to a public repo.
- A separate release manifest should carry only signed-off cards. The seed catalog alone never grants release permission.

**Native code (draft PR implementation)**
1. `ios/AroomaNative/Fall2026.swift` decodes the bundled manifest, checks a complete rights-cleared 30-card season and presents `AutumnArchiveScreen` with a native flip/share inspector. It remains hidden unless all 30 image assets exist and are approved.
2. `ios/AroomaNative/Commercial.swift` adds the Autumn Archive entry in Cards only when the season is ready; browse does not modify owned bottles or personal cards.
3. `ios/AroomaNative.xcodeproj/project.pbxproj` includes the Swift file and catalog JSON; use the existing `Assets.xcassets` for 30 named image sets.
4. `scripts/package-fall-archive.mjs` validates reviewed flags and 30 approved JPEGs, then copies them into the asset catalog.
5. `scripts/check-fall-archive.mjs --release` requires the complete approved, fact-checked, rights-cleared set and packaged assets.
6. The current native back view displays truthful brand/name/variant details. Build out verified top/heart/base note strips before shipping.

**Production pipeline**
`manifest + reviewed refs -> image generation -> candidate folder -> visual/product/legal QA -> approved masters -> optimized bundle assets -> Xcode compile -> TestFlight`.

**Permissions / infrastructure:** No new network, backend, account, ad permissions or App Store products. Image generation occurs outside the mobile app before release. A production script could use the image API only after the owner configures a paid API key in a secure production workflow; never embed keys in the repository or iPhone app.

## 8. Risks, open questions and mitigations

| Risk | Proposed treatment | Decision |
| --- | --- | --- |
| Incorrect product images or concentration | Product-specific approved reference; primary-source variant verification before use | Production owner |
| Copyright and trademark use | Per-art third-party content review; block publication without clearance | Rights reviewer / owner |
| Inconsistent generative typography | Post-layout text composition using verified fields; visual QA | Production owner |
| Large bundled app | Compress 30 images, target roughly 10-30 MB total; measure final IPA | Engineering |
| Existing 4-card library conflicts | Keep Fall browse identity and IDs separate from the previous card editions and ownership | Engineering |
| Generating 30 in one opaque step | Six-image pilot, inspect, then finish remaining 24 | Production owner |
| Owner asks "next build" but art isn't ready | Do not ship empty placeholders or imply completion; build only after 30 approved assets are integrated | Release owner |

## 9. Verification and prototype plan

### Acceptance criteria
1. Given a shipped TestFlight build, Cards > Autumn Archive shows **exactly 30** unique complete card fronts with correct names and no placeholders.
2. Given offline mode, all 30 open, flip and share without internet; no placeholder artwork.
3. Given one missing/unapproved image, release packaging validation **fails** rather than hiding a missing design.
4. Given a photo-driven title, the artwork shows no invented bottle shape, wrong cap or fake product concentration; human review is required.
5. Given an existing user library, the update leaves created cards, personal images, bottles, wishlists and purchases intact.
6. Given an iPhone with Reduce Motion, inspection works without animated foil; with motion enabled, it uses existing native materials.
7. Signed TestFlight upload follows the owner's existing `arooma-testflight` Codemagic workflow, and the uploaded build is verified in App Store Connect.

### Checks
- `npm run docs:check`, `npm run test:docs` and project `npm test` where applicable.
- GitHub native unsigned simulator Xcode compile on a PR and after merge.
- 30/30 approved front assets and checksums; verify design crops and product fidelity by review.
- Hardware QA on iPhone: loading speed, swipes, memory, reduced motion, offline and sharing.

### Prototype / owner test
- Use the existing MYSLF approved front as quality target, then create six category-diverse pilot cards. They must be **real finished artwork**, not SwiftUI color filters.
- Test on the same target iPhone at card size and full inspect size.
- Ask: Can you identify the fragrance without reading the title? Does the jar/bottle look correct? Would you keep or share this card?

## 10. Rollout, rollback and release

1. Plan + seed manifest on a dedicated branch, unmerged until approved artwork and app integration exist.
2. Produce and review six prototypes, then remaining 24 using the locked production criteria.
3. Run `node scripts/package-fall-archive.mjs` and then `node scripts/check-fall-archive.mjs --release` after all images and rights are approved. Complete the note-map card back.
4. Run all checks. Do not merge while any of the 30 images are missing or rights status is unresolved.
5. Merge to `main` only after criteria pass, then run existing manual Codemagic `arooma-testflight` for bundle `com.graymatter.arooma`. Verify in internal TestFlight.
6. Rollback by reverting the catalog feature and asset bundle commits; leave existing created-card and owned-bottle persistence untouched.

**Current status:** The manifest and gallery integration are ready as a draft branch. **Zero of these new 30 designs has been generated, QA-reviewed, licensed or shipped.** The Autumn Archive screen stays hidden until 30 approved images are bundled. Existing Dior art is separate and requires its own rights review. The next TestFlight build cannot truthfully contain 30 finished cards until the remaining art, note-map and QA work is completed.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-31 | Plan the Fall 2026 collection as 30 pre-generated, hand-verified, bundled card fronts and data-backed native backs; no backend for season one | Owner-directed; implementation pending | This spec, `assets/collectibles/seasons/fall-2026/catalog.json` |
