#!/usr/bin/env node
// Autumn Archive production manifest gate.
// Usage: node scripts/check-fall-archive.mjs [--release]
// Default checks the 30-item seed. --release fails if an art/rights gate is incomplete.
import fs from "node:fs";
import path from "node:path";

const base = path.resolve("assets/collectibles/seasons/fall-2026");
const release = process.argv.includes("--release");
const failures = [];
const fail = message => failures.push(message);
const data = JSON.parse(fs.readFileSync(path.join(base, "catalog.json"), "utf8"));
if (data.version !== 1) fail("Unsupported catalog version");
if (!Array.isArray(data.cards) || data.cards.length !== 30) fail("Expected exactly 30 cards");
if (data.collectionID !== "fall-2026-men") fail("Wrong collection identity");

const ids = new Set();
const ranks = new Set();
for (const card of data.cards ?? []) {
  if (ids.has(card.id)) fail("Duplicate ID: " + card.id);
  if (ranks.has(card.rank)) fail("Duplicate rank: " + card.rank);
  ids.add(card.id);
  ranks.add(card.rank);
  for (const key of ["id", "house", "name", "variant", "sceneBrief", "frontMaster", "frontAppAsset"]) {
    if (!card[key] || typeof card[key] !== "string") fail(card.id + ": missing " + key);
  }
  if (!/^[a-z0-9-]+$/.test(card.id ?? "")) fail("Unsafe ID: " + card.id);
  if (card.frontMaster !== "masters/" + card.id + "-front.png") fail(card.id + ": wrong master path");
  if (card.frontAppAsset !== "approved/" + card.id + "-front.jpg") fail(card.id + ": wrong app-art path");
  if (release) {
    if (card.status !== "approved" || card.artRightsCleared !== true ||
        card.productFactsVerified !== true || card.referencePhotoApproved !== true) {
      fail(card.id + ": cannot ship without approved art, verified identity and rights review");
    }
    const fullPath = path.join(base, card.frontAppAsset);
    if (!fs.existsSync(fullPath)) {
      fail(card.id + ": missing native image " + card.frontAppAsset);
    } else if (fs.statSync(fullPath).size < 20_000) {
      fail(card.id + ": image suspiciously small");
    }
    const imageSet = path.resolve("ios/AroomaNative/Assets.xcassets", "fall2026-" + card.id + ".imageset");
    const contents = path.join(imageSet, "Contents.json");
    const image = path.join(imageSet, "front.jpg");
    if (!fs.existsSync(contents) || !fs.existsSync(image)) {
      fail(card.id + ": image not packaged in native Xcode assets");
    } else {
      const meta = JSON.parse(fs.readFileSync(contents, "utf8"));
      if (!(meta.images ?? []).some(x => x.filename === "front.jpg")) {
        fail(card.id + ": asset set does not reference the card JPG");
      }
    }
  }
}
for (let i = 1; i <= 30; i++) if (!ranks.has(i)) fail("Missing rank " + i);

if (failures.length) {
  for (const problem of failures) console.error("FAIL", problem);
  process.exit(1);
}
console.log("Autumn Archive: 30/30 manifest entries valid (" + (release ? "APPROVED RELEASE" : "seed/brief only") + ")");
