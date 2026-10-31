# Arooma — canonical signature and Higgsfield pen-writing intro

**Status:** Brand asset master delivered 2026-10-31. Native SwiftUI integration and real-device QA are the next work item.

## Identity lock

The signature is a **one-off original calligraphic wordmark for the literal name Arooma**, not a distributable alphabet font. It is the single source of truth for the brand's lettering, modeled on expressive luxury-house hand lettering with variable brush pressure, fine pointed-pen connectors and flourished entry/exit strokes. Do not use Snell Roundhand, Apple Chancery, other generic cursive, or regenerate/retype this logo.

## Shipped assets

| Path | Purpose |
| --- | --- |
| `assets/brand/arooma-signature.svg` | Scalable vector silhouette of the fixed signature, transparent; `currentColor` fill. |
| `assets/brand/arooma-signature-alpha.png` | Transparent grayscale master extracted from the generated lettering; 1220×482. |
| `ios/AroomaNative/Assets.xcassets/AroomaSignature.imageset/arooma-signature.png` | Same transparent alpha master, registered as an Xcode image asset. |
| `ios/AroomaNative/Resources/AroomaIntroInkLight.mp4` | Higgsfield-powered ink-writing motion, on warm ivory `#F4EEE4` with dark `#272124` lettering. |
| `ios/AroomaNative/Resources/AroomaIntroInkDark.mp4` | Same sequence on dark navy/plum `#191923` with lilac `#C9B6D9` lettering. |
| `docs/design/prompts/OPUS_55_NATIVE_INTEGRATION.md` | Updated complete Claude Opus 5.5 integration brief. |

Videos are 1280×720, H.264, silent, approximately 3.7 seconds, and deliberately small enough to bundle with the iPhone app. Ensure the Xcode app target has **Copy Bundle Resources** entries for both. They are not network video URLs.

## Provenance and motion treatment

- Original still wordmark created with **GPT Image 2.5 on Higgsfield**, generation `ae4374c1-bebc-4779-b044-aa9b5895afd3`; original canvas was 1344×752 on ivory.
- Realistic pen-writing motion generated using **MiniMax H3 on Higgsfield**, generation `9e5eb5b8-d9ec-4e86-9b47-b1c8b2dcb13d`, with a blank initial keyframe and the canonical wordmark as the finishing keyframe.
- Two mobile-ready recolored/muted playback masters derived from that completed H3 output; neither creates new letterforms. The authoritative letters remain the SVG and transparent PNG.
- The reference generation is not a licensed existing artist's typeface; user-supplied calligraphy examples were stylistic guidance only.
- The AI animation can fluctuate subtly from the static letters. **Do not silently change the brand silhouette to match a generative frame**. Align/mask the video to the approved static image or crossfade cleanly to the static master. No new generative logo attempts by Opus.

## Native integration acceptance

1. Intro uses the supplied video or a frame/mask treatment derived exclusively from these assets; no live font render masquerading as a signature.
2. First frame clean background, letter strokes appear sequentially with natural brush and hairline pressure; final frame holds the canonical silhouette without snap/morph.
3. Intro centers with `scaledToFit`, preserves flourishes, no cropping or translucent player chrome. Dark/light palettes correspond to their clips.
4. First-run ritual may animate; returning users go straight to last collection. The replay action is optional and discoverable.
5. Reduce Motion shows static signature immediately; VoiceOver announces "Arooma" only once.
6. Video decodes and plays smoothly on a physical iPhone, with no black flash, hitch, audio, network dependency or broken bundle reference.

**Known validation limit:** Higgsfield generation completed and files were authored; a real-device preview and comparison against the owner's calligraphy references still require owner review. Do not claim final visual approval or on-device frame pacing from this handoff.
