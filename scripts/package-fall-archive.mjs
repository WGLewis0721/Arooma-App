#!/usr/bin/env node
// Package 30 verified fall card fronts as compiled Xcode image sets.
// Run only after source images and per-card rights/status reviews are complete.
// Usage: node scripts/package-fall-archive.mjs
import fs from "node:fs";
import path from "node:path";

const root = path.resolve("assets/collectibles/seasons/fall-2026");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "catalog.json"), "utf8"));
if (manifest.cards?.length !== 30) throw new Error("30 catalog items required");

const output = path.resolve("ios/AroomaNative/Assets.xcassets");
for (const card of manifest.cards) {
  if (card.status !== "approved" || card.artRightsCleared !== true ||
      card.productFactsVerified !== true || card.referencePhotoApproved !== true) {
    throw new Error("Not cleared to ship: " + card.id);
  }
  const source = path.join(root, card.frontAppAsset);
  if (!fs.existsSync(source)) throw new Error("Missing approved front: " + source);
  const bytes = fs.readFileSync(source);
  if (bytes.length < 20_000 || bytes[0] !== 0xff || bytes[1] !== 0xd8) {
    throw new Error("Invalid JPEG: " + card.id);
  }
}

// The complete set is validated before touching output: avoid partial seasons.
for (const card of manifest.cards) {
  const dir = path.join(output, "fall2026-" + card.id + ".imageset");
  fs.mkdirSync(dir, { recursive: true });
  fs.copyFileSync(path.join(root, card.frontAppAsset), path.join(dir, "front.jpg"));
  fs.writeFileSync(path.join(dir, "Contents.json"),
    JSON.stringify({
      images: [{ filename: "front.jpg", idiom: "universal" }],
      info: { author: "xcode", version: 1 }
    }, null, 2) + "\n");
}
console.log("Packaged 30 Autumn Archive imagesets in the existing native Xcode asset catalog");
