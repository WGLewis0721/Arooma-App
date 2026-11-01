#!/usr/bin/env node
// Validate an Autumn Archive seed or enforce the production release gate.
// Usage: node scripts/check-fall-archive.mjs [--release]
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

const base = path.resolve('assets/collectibles/seasons/fall-2026');
const release = process.argv.includes('--release');
const failures = [];
const fail = message => failures.push(message);
const data = JSON.parse(fs.readFileSync(path.join(base, 'catalog.json'), 'utf8'));
if (data.version !== 1) fail('Unsupported catalog version');
if (!Array.isArray(data.cards) || data.cards.length !== 30) fail('Expected exactly 30 cards');
if (data.collectionID !== 'fall-2026-men') fail('Wrong collection identity');

// Read JPEG start-of-frame dimensions without adding an external dependency.
function jpegSize(bytes) {
  if (bytes.length < 10 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return null;
  let p = 2;
  while (p + 4 < bytes.length) {
    if (bytes[p] !== 0xff) return null;
    while (p < bytes.length && bytes[p] === 0xff) p++;
    const marker = bytes[p++];
    if (marker === 0xd9 || marker === 0xda) break;
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (p + 2 > bytes.length) return null;
    const length = bytes.readUInt16BE(p);
    if (length < 2 || p + length > bytes.length) return null;
    const isSOF = (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker));
    if (isSOF) {
      if (length < 7) return null;
      return { height: bytes.readUInt16BE(p + 3), width: bytes.readUInt16BE(p + 5) };
    }
    p += length;
  }
  return null;
}

const minimums = { productFidelity: 27, composition: 17, finish: 17,
                   typography: 13, scentSpecificity: 8, border: 4 };
const maximums = { productFidelity: 30, composition: 20, finish: 20,
                   typography: 15, scentSpecificity: 10, border: 5 };
function validateReviews(card) {
  if (!Array.isArray(card.qualityReviews) || card.qualityReviews.length < 2) {
    fail(card.id + ': two independent quality reviews required');
    return;
  }
  const reviewers = new Set();
  for (const review of card.qualityReviews) {
    if (!review.reviewerID || reviewers.has(review.reviewerID)) {
      fail(card.id + ': quality reviewers need distinct IDs');
      continue;
    }
    reviewers.add(review.reviewerID);
    let score = 0;
    for (const [key, minimum] of Object.entries(minimums)) {
      const value = review[key];
      if (!Number.isInteger(value) || value < minimum || value > maximums[key]) {
        fail(card.id + ': ' + key + ' failed threshold for ' + review.reviewerID);
      } else score += value;
    }
    if (score < 90) fail(card.id + ': total score below 90 for ' + review.reviewerID);
    if (review.productIdentityConfirmed !== true || review.allTextVerified !== true ||
        review.fullBorderVisible !== true || review.phoneLegible !== true) {
      fail(card.id + ': reviewer hard gates incomplete for ' + review.reviewerID);
    }
  }
}

const ids = new Set();
const ranks = new Set();
const hashes = new Map();
for (const card of data.cards ?? []) {
  if (ids.has(card.id)) fail('Duplicate ID: ' + card.id);
  if (ranks.has(card.rank)) fail('Duplicate rank: ' + card.rank);
  ids.add(card.id);
  ranks.add(card.rank);
  for (const key of ['id','house','name','variant','sceneBrief','frontMaster','frontAppAsset']) {
    if (!card[key] || typeof card[key] !== 'string') fail(card.id + ': missing ' + key);
  }
  if (!/^[a-z0-9-]+$/.test(card.id ?? '')) fail('Unsafe ID: ' + card.id);
  if (card.frontMaster !== 'masters/' + card.id + '-front.png') fail(card.id + ': wrong master path');
  if (card.frontAppAsset !== 'approved/' + card.id + '-front.jpg') fail(card.id + ': wrong app-art path');
  if (release) {
    if (card.status !== 'approved' || card.artRightsCleared !== true ||
        card.productFactsVerified !== true || card.referencePhotoApproved !== true) {
      fail(card.id + ': missing artwork, factual or rights approval');
    }
    validateReviews(card);
    const fullPath = path.join(base, card.frontAppAsset);
    const imageSet = path.resolve('ios/AroomaNative/Assets.xcassets', 'fall2026-' + card.id + '.imageset');
    const contents = path.join(imageSet, 'Contents.json');
    const packaged = path.join(imageSet, 'front.jpg');
    if (!fs.existsSync(fullPath)) {
      fail(card.id + ': missing approved card image');
    } else {
      const bytes = fs.readFileSync(fullPath);
      if (bytes.length < 20_000) fail(card.id + ': suspiciously small image');
      const dimensions = jpegSize(bytes);
      if (!dimensions || dimensions.width < 1180 || dimensions.height < 1720 ||
          Math.abs(dimensions.width / dimensions.height - 59 / 86) > .005) {
        fail(card.id + ': JPG must be at least 1180x1720, ratio 59:86 (+/-0.005)');
      }
      const hash = createHash('sha256').update(bytes).digest('hex');
      if (hashes.has(hash)) fail(card.id + ': duplicate image bytes with ' + hashes.get(hash));
      hashes.set(hash, card.id);
      if (!fs.existsSync(packaged) || !fs.readFileSync(packaged).equals(bytes)) {
        fail(card.id + ': packaged image must match approved JPEG exactly');
      }
    }
    if (!fs.existsSync(contents)) {
      fail(card.id + ': image set missing Contents.json');
    } else {
      try {
        const meta = JSON.parse(fs.readFileSync(contents, 'utf8'));
        if (!(meta.images ?? []).some(x => x.filename === 'front.jpg')) {
          fail(card.id + ': image set does not reference card JPEG');
        }
      } catch { fail(card.id + ': malformed image set'); }
    }
  }
}
for (let rank = 1; rank <= 30; rank++) if (!ranks.has(rank)) fail('Missing rank ' + rank);

if (failures.length) {
  for (const problem of failures) console.error('FAIL', problem);
  process.exit(1);
}
console.log('Autumn Archive: 30/30 valid (' + (release ? 'APPROVED RELEASE' : 'seed/brief only') + ')');
