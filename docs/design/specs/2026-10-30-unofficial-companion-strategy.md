# Arooma unofficial fragrance companion: product and rights strategy

> Part of the [Arooma design brain](../README.md). Follow [PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). **Policy authority:** [brand/THIRD_PARTY_CONTENT_POLICY.md](../brand/THIRD_PARTY_CONTENT_POLICY.md).

| Property | Decision |
| --- | --- |
| Request | “We'll run the same play” after examining Yugipedia's unofficial, ad-supported collectible-database model |
| Date | 2026-10-30 |
| Scope | Strategy and policy documentation only; no new assets, IAP, image catalog, SDKs or app UI |
| Size | L: new real-brand catalog surface, external content and distribution-risk exception |
| Status | Companion model chosen by owner; specific image-rights claims and App Review path **unapproved** |
| References | [existing Warm Archive](../brand/BRAND_BOARD.md), [collectible art direction v3](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md), [third-party content policy](../brand/THIRD_PARTY_CONTENT_POLICY.md) |

## 1. Problem

Users who collect real fragrance bottles want to find exact fragrances and build a visually rich, organized personal cabinet. The current fictional-only demo can prove layout and motion, but it doesn't provide the searchable, trustworthy real-fragrance catalog that makes a companion utility indispensable. Yugipedia offers a model for useful organization with optional purchases; its public fair-use argument is **not proof of permission or a guarantee of App Review success**.

## 2. Scope and principles

Goals: genuine discover/search/add loop, exact product/concentration identity, a practical cabinet separate from cinematic collectible cards, accurate source-linked metadata, optional native IAP for features, user-controlled photos, and rights-reviewable media.

Non-goals: importing all Dior/YSL/Prada site photos, copying Yugipedia card UI, selling branded card art, asserting blanket fair use, circumventing App Review, launching paid ads now, representing Arooma as affiliated with any house, compromising offline/private collections.

**Appetite:** Stage 1 docs and zero-risk architecture, then a separate design/implementation ticket. Zero public third-party images until rights basis and review are documented.

## 3. Relevant constraints and exceptions

- Existing [Warm Archive](../brand/BRAND_BOARD.md) UI and fictional demo remain unchanged. Standalone Archive Foil concepts are independent.
- Real fragrance **names and factual identifiers** for collection and search are the intended product expansion. This user direction supersedes the assumption that a future app must always be fictional, but it does **not authorize immediate publication** or changing existing demo data.
- Brand photography, logo packs, brand site scraping and generative approximations have separate rights issues. A user decision for the companion model does **not establish copyright permission**.
- Apple's [Review Guidelines 5.2.1, 5.2.2](https://developer.apple.com/app-store/review/guidelines/) generally require appropriate IP and service permissions and Apple [may request rights documentation](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review). US fair use [17 USC 107](https://uscode.house.gov/us/usc/119-120/t17/s107/) is case specific.
- The Remove Ads option, if implemented in an iOS app, must follow Apple 3.1.1 IAP. No specific price or implementation selected.
- Arooma must still meet 4.2: substantive functionality beyond a content gallery.

## 4. Alternatives and decision

| Option | Benefit | Concern | Status |
| --- | --- | --- | --- |
| A: fictional-only catalog | Little third-party media risk | Fails the real-collection discovery goal | Rejected as the complete future product |
| B: copy Yugipedia's image acquisition and fair-use disclaimer wholesale | Fast recognition; precedent exists | High legal/App Review risk; disclaimer is not a permission grant | **Rejected** |
| C: Yugipedia-style companion utility + per-asset rights review + original Arooma art | Product value independent of photos, maintainable provenance and takedown paths, clear paid-feature model | Catalog/data/rights groundwork required | **Chosen** |

## 5. Breadboard: intended experience, not built

```text
Discover / Search
  ├─ Search name, maker, concentration, year, top notes
  ├─ Exact variant page: source-linked text + cleared image/fallback
  └─ [+ Add] -> personal cabinet record, attached source id

Cabinet
  ├─ Cover Flow / Stack / Fan (existing separate experience)
  ├─ Owner photo, optional generated art (rights-reviewed if public)
  ├─ Wear, refill, seasonal shelf and favorites
  └─ Flip to verified TOP / HEART / BASE and collection notes

Settings
  ├─ Backup / Restore
  ├─ About / Unofficial status / Rights contact
  └─ Optional Remove Ads (native platform decision pending)
```

**States:** empty catalog and no internet (saved records still work), no image rights (use original fallback art), unknown notes (omit), ambiguous variant (ask user to select exact bottle), declined photo-share (keep local), deleted asset (graceful replacement), failed payment (free core remains), restored purchase, complaint/takedown (disable contested media), failed catalog lookup (no fake data).

## 6. Platform, privacy and accessible content

- App Store compliant iOS implementation may require native wrapper or native app for IAP; current PWA should not fake native entitlement.
- Ads, analytics or transactions require their own privacy analysis, policy, SDK audit and opt-out handling.
- Images never replace accessible real text about fragrance metadata; text is readable under Dynamic Type and VoiceOver.
- Any user's bottle photo stays private and local by default; sharing is opt-in. Backups distinguish ownership data from distributable catalog assets.
- Image-only cards aren't the only way to read information; maintain source-grounded accessible text records.

## 7. Technical strategy and milestones

1. **Legal/content boundary first:** adopt [content policy](../brand/THIRD_PARTY_CONTENT_POLICY.md); define About notice, rights-owner contact, claim handling and per-asset rights ledger; seek specialist IP review if relying on fair use for existing photos.
2. **Catalog foundation:** decide trusted sources; create a local-first variant-specific catalog schema. Separate facts from images and rights metadata. No scraping until site/API terms are understood.
3. **Three-fragrance proof:** approved/licensed/owner-supplied **private** photos only; test search -> add -> flip -> record -> export, with a fallback if no image rights.
4. **Collectible art:** preserve Archive Foil v3; opt-in generation using sourced notes and user bottle identity, not automatic copying of manufacturer marketing art. Decide distribution/sharing permission per asset.
5. **Monetization later:** compare ad-free IAP with no-ads one-time supporter unlock or premium collection tools. Choose model after a prototype and privacy review, not by copying Yugipedia's $1.99 anecdote.
6. **Review packet:** rights documents, source/permission ledger, reviewer access, privacy policy, in-app notice, purchase/restore flow if implemented, demonstration of real use.

**Never mutate current fictional demo or ship proprietary content based only on this strategy note.** A later coded feature needs a separate implementation PR and an explicit decision on provenance sources.

## 8. Risks and decisions

| Risk | Default | Owner of resolution |
| --- | --- | --- |
| Apple asks to prove photo rights | Use licensed, owner-submitted private, or original fallback imagery; don't rely on blanket claim | Product owner + counsel |
| Generic “fair use” claim is overbroad | No blanket claim; specific case-by-case written assessment | Counsel |
| User image becomes publicly shared | Private by default; explicit review/consent before sharing | Product/design |
| Confusion that a house endorses Arooma | Arooma-first identity and prominent About notice | Design + marketing |
| Fees/ad SDK degrade premium feel | Keep free usable core, defer ads and price decision | Product owner |
| Notes/year wrong across variants | Official variant-specific data source and provenance | Content curator |
| Rights owner requests removal | Contact/takedown route; unpublish image independent of factual bottle record | Support/legal |
| Real brand data conflicts with fictional demo | Feature-gated catalog and separate storage until approved | Engineering |

## 9. Acceptance, validation and rollout

- [ ] Companion strategy and legal/media policy are indexed in the design brain.
- [ ] Official/unofficial wording never implies affiliation.
- [ ] No third-party image enters catalog without per-asset documented basis and eligible public-distribution scope.
- [ ] Stored bottle facts retain correct maker/variant/date and source references.
- [ ] A user can add and use a bottle even when no image is available.
- [ ] Rights concerns can disable a photo without deleting the underlying owner record.
- [ ] Native IAP, if built, provides Apple-compliant purchase and restore and doesn't monetize unlicensed media rights.
- [ ] Ship decision includes actual rights review, privacy check and App Review evidence; another app's approval isn't substituted.
- [ ] Existing fictional demo, Warm Archive and Archive Foil v3 styling remain unchanged in this docs-only PR.

**Tests now:** repo design-doc link/format checks and confirm no runtime diff. **Tests owed:** actual product prototype on iPhone and distribution rights review. **Rollback:** revert strategy doc PR if decision changes; no feature roll-forward occurs automatically.

## 10. Decision log

2026-10-30: Owner chose the **unofficial collection-companion business direction** inspired by Yugipedia. Implementation/price/image rights are *not decided*. No automatic public-image acquisition approved.

## 11. Sources

- [Yugipedia App Store description/disclaimer](https://apps.apple.com/us/app/yugipedia-deck-builder/id1026470546)
- [Apple App Review guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple rights-documentation instructions](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review)
- [Fair use, 17 USC §107](https://uscode.house.gov/us/usc/119-120/t17/s107/)
