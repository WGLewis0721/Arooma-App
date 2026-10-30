# Arooma | Third-party fragrance content and rights policy

> Part of the [Arooma design brain](../README.md). See the [unofficial-companion rollout spec](../specs/2026-10-30-unofficial-companion-strategy.md). **Status: product direction accepted, content rights and legal determinations still pending.**

> Summary: Arooma is an **independent companion utility** for identifying, logging, comparing, organizing and sharing fragrance collections, modeled on the *useful app workflow* of independent collectible databases such as Yugipedia. Support real house/fragrance names as factual identifiers where legally appropriate. The existence of another App Store app or its fair-use declaration does **not** license third-party brand photography or guarantee Arooma approval. Product and visual art can be original; image/copy provenance must be tracked per asset.

## Positioning, names and affiliations

- Brand: **Arooma**. Never use a third-party fragrance brand in the app name, developer name or icon, and do not mimic official brand UI.
- Fragrance house, concentration, product, note, year and classification can appear as **accurate factual database fields** for identification; preserve correct names and distinguish versions. Trademarks remain with their owners.
- Display a plain-language notice in **About > Legal** and a link from the App Store listing; do not imply sponsorship, verification or authorized partnerships.
- Suggested copy, subject to legal review:

  > Arooma is an independent fragrance collection and discovery app. It is not affiliated with, sponsored by, or endorsed by the fragrance brands shown. Brand names and trademarks belong to their respective owners and are used to identify fragrances. Photos and other creative assets belong to their respective rights holders where applicable. For content or rights concerns, contact [PUBLISHED SUPPORT CONTACT].

  Never publish a bracket placeholder or make a statement about image rights that isn't true. A disclaimer is **not a license or an automatic fair-use defense**.
- No claim of being “official”, “authorized”, “endorsed”, “verified authentic” or “brand certified” without evidence. Do not imply Arooma's collectible treatment is a maker-issued card or regulated fragrance rarity.

## Content-by-content source policy

| Item | Default | Restriction or decision gate |
| --- | --- | --- |
| Fragrance house/product name, concentration, year | Accurate original factual entries with source references | No misleading sponsorship; verify specific variant |
| Published scent notes and positioning | Original concise **paraphrase** and source links | Do not reproduce lengthy house editorial/campaign copy without rights |
| User's own bottle photo | User submits and uses locally for their cabinet | User must have permission for sharing; local-private by default; removal/export controls |
| Arooma-generated card artwork | Arooma-authored composition and independently generated/cleared photo plates | Product trade dress, trademark presentation and recognizable bottle source still need review; AI output does not cleanse copied source IP |
| Licensed or permitted supplier photographs | Use under documented license and its permitted distribution contexts | Store rights proof and permitted duration, scope, resize, attribution |
| Publicly found official product photo or campaign still | **Reference for research only** by default; no automatic app/catalog import | Separate documented copyright/fair-use assessment or explicit permission is required before distribution. Public availability ≠ public domain |
| User-uploaded third-party photo | User attests they are permitted to supply it | Do not automatically promote it into a public catalog or make other users' default image |
| Brand trademarks/logos in full card art | Prefer the authentic mark already on owner-supplied bottle image | Extra isolated brand logos/campaign branding require a rights/confusion assessment |

### Fair-use review

Fair use is **specific to a particular work and purpose**, not a platform-wide checkbox. Before using a copyrighted photo without a license, record counsel's/qualified review of (1) purpose including commercial and whether transformative; (2) creative nature of work; (3) amount copied; (4) market substitution/harm. Record why the image is necessary for identification, whether a smaller crop or lower-resolution illustration suffices, and whether permission/licensed alternatives are available.

**Do not infer fair use from:** a public URL, another unofficial app, a “fair use” statement, credits/attribution, an ad-free purchase, a generative re-render, a disclaimer or the fact the app is useful.

U.S. fair use is fact-specific; **other jurisdictions have different rules**. Apple Review Guideline 5.2.1 generally prohibits unauthorized protected third-party content and 5.2.2 separately covers third-party website/services permissions. Apple can demand documentation, reject the app, or remove it after approval.

### Minimal provenance entry per image

```yaml
asset_id: "arooma:fragrance:variant:asset-version"
house: "..."
fragrance: "..."
concentration: "..."
asset_type: "owner_photo | licensed | original | generated | third_party"
creator_or_rightsholder: "..."
source_url_or_user_local_ref: "..."
rights_basis: "owner_submission | license | original | reviewed_exception | unverified"
rights_document_or_review_ref: "..."
permitted_uses: ["private_library"] # add public_catalog / share / advertising only if cleared
jurisdictions_and_expiration: "..."
published_status: "private | approved | hold | removed"
reviewed_by_and_date: "..."
takedown_contact: "..."
```

**Asset release rule:** publish to shared in-app catalog / marketing / cards only when `published_status: approved` and a reviewed permitted-use scope covers it. Otherwise keep private or replace with first-party Arooma graphic. No scraped official-site library is approved by this product decision.

## Product features and monetization

The free app must be a useful, functioning **fragrance collection manager**: browse verified facts, find and save bottles, inspect concise profiles, track wears/remaining, group on shelves, export/restore data, and optionally share one's own collection. Arooma is not a substitute for buying fragrances or a storefront of copyrighted brand ads.

Possible business model, **not implemented by this policy**:
- Free useful core experience; optional ads only if they meet Apple's privacy/ad rules and don't ruin the cabinet experience.
- One-time **Remove Ads** or optional premium collection-management features via Apple's In-App Purchase for iOS, with restore-purchases support and clear pricing. The Yugipedia user's $1.99 purchase is an example, **not a committed Arooma price**.
- Payment unlocks **Arooma functionality**, not rights to third-party photography, name licensing or access to otherwise unauthorized copyrighted content.
- Do not implement ads/IAP until native-vs-PWA platform decision, App Store product IDs, privacy policy and accessibility are addressed.

## App Review / operational controls

- Prepare a 5.2 rights ledger and authorization/evidence pack that can be shown privately to Apple; consult qualified IP counsel on actual fair-use plans before launch.
- Maintain a public support channel for rights-owner removal requests, verify claims, disable implicated assets promptly, record resolution and retain license/evidence records. This is an operational workflow, not a claim of DMCA safe harbor.
- Keep a private-to-owner photo path distinct from a publicly distributed image catalog. If sharing exists, provide granular opt-in, not default public redistribution.
- Minimize/avoid web-scraping; comply with third-party source terms and rate limits even when content is publicly viewable.
- Separate factual fragrance records from rights-restricted media so cards work with fallback art if an image is removed.
- Do **not** publish a claim that Arooma's use of all images is “protected by Fair Use”. Any such conclusion requires a case-specific analysis.
- Check Apple Guideline 4.2 (utility) and 3.1.1 (in-app purchase) in addition to 5.2; App Review approval is not a court determination.

## Source material checked 2026-10-30

- [Apple App Review Guidelines, §§3.1.1, 4.1/4.2 and 5.2](https://developer.apple.com/app-store/review/guidelines/)
- [Apple's App Review documentation requirements for third-party IP](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review)
- [U.S. fair-use statute, 17 USC §107](https://uscode.house.gov/us/usc/119-120/t17/s107/)
- [Yugipedia Deck Builder App Store listing and its unofficial/fair-use declaration](https://apps.apple.com/us/app/yugipedia-deck-builder/id1026470546)

**Status warning:** This is a product and operational policy, not legal advice, a license, a fairness determination, an App Store approval prediction, or permission to publish third-party photos.
