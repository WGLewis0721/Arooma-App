import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { BUDGETS, SUMMARY_OVER_BYTES, checkDesignDocs, syncRulesCard } from "./design-docs.mjs";
import { renderTokens } from "./design-tokens.mjs";

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

function write(root, file, text) {
  mkdirSync(dirname(join(root, file)), { recursive: true });
  writeFileSync(join(root, file), text);
}

const POINTER = "See [map](docs/design/README.md) and docs/design/PLAN_SPEC_PROTOCOL.md.\n";

function healthyTree() {
  const root = mkdtempSync(join(tmpdir(), "design-docs-"));
  write(root, "docs/design/README.md", "# Map\n\nSee brand/RULES.md and PLAN_SPEC_PROTOCOL.md and specs/.\n");
  write(root, "docs/design/brand/RULES.md", "# Rules\n\n> [map](../README.md)\n");
  write(root, "docs/design/PLAN_SPEC_PROTOCOL.md", "# Protocol\n\n> [map](README.md)\n");
  write(root, "docs/design/specs/README.md", "# Specs\n\n> [map](../README.md)\n");
  for (const f of ["CLAUDE.md", "GEMINI.md", "AGENTS.md"]) write(root, f, POINTER);
  write(root, ".github/copilot-instructions.md", POINTER.replace("(docs/", "(../docs/"));
  return root;
}

test("the real repository's design docs are consistent", () => {
  assert.deepEqual(checkDesignDocs(REPO_ROOT), []);
});

test("a healthy tree has no problems", () => {
  assert.deepEqual(checkDesignDocs(healthyTree()), []);
});

test("a broken relative link is reported", () => {
  const root = healthyTree();
  write(root, "docs/design/brand/RULES.md", "# Rules\n\n> [map](../README.md)\n\n[gone](missing.md)\n");
  assert.ok(checkDesignDocs(root).some((p) => p.includes("broken link to missing.md")));
});

test("a document missing from the map or without a link back is reported", () => {
  const root = healthyTree();
  write(root, "docs/design/brand/ORPHAN.md", "# Orphan\n");
  const problems = checkDesignDocs(root);
  assert.ok(problems.some((p) => p.includes("ORPHAN.md: not on the map")));
  assert.ok(problems.some((p) => p.includes("ORPHAN.md: does not link back")));
});

test("a pointer file that stops pointing at the design brain is reported", () => {
  const root = healthyTree();
  write(root, "GEMINI.md", "Do things.\n");
  assert.ok(checkDesignDocs(root).some((p) => p.includes("GEMINI.md: does not mention docs/design/README.md")));
});

const CARD = "<!-- card:start -->\nRule one.\n<!-- card:end -->\n";
const COPY = (body) => `<!-- design-rules-card:start -->\n${body}\n<!-- design-rules-card:end -->\n`;

function treeWithCard(copyBody = "Rule one.") {
  const root = healthyTree();
  write(root, "docs/design/RULES_CARD.md", `# Card\n\n> [map](README.md)\n\n${CARD}`);
  write(root, "docs/design/README.md", "# Map\n\nSee brand/RULES.md and PLAN_SPEC_PROTOCOL.md and specs/ and RULES_CARD.md and packs/p.md.\n");
  for (const f of ["CLAUDE.md", "GEMINI.md", "AGENTS.md"]) write(root, f, POINTER + COPY(copyBody));
  write(root, ".github/copilot-instructions.md", POINTER.replace("(docs/", "(../docs/") + COPY(copyBody));
  return root;
}

test("a tree with a fresh rules card has no problems", () => {
  assert.deepEqual(checkDesignDocs(treeWithCard()), []);
});

test("a stale or missing card copy is reported and sync repairs it", () => {
  const root = treeWithCard("Old rule.");
  const problems = checkDesignDocs(root);
  assert.ok(problems.some((p) => p.includes("CLAUDE.md: rules card is stale")));
  write(root, "GEMINI.md", POINTER);
  assert.ok(checkDesignDocs(root).some((p) => p.includes("GEMINI.md: missing the rules card block")));
  assert.ok(syncRulesCard(root).length >= 2);
  assert.deepEqual(checkDesignDocs(root), []);
});

test("an oversized card, map or pack is reported", () => {
  const root = treeWithCard();
  write(root, "docs/design/RULES_CARD.md", `# Card\n\n> [map](README.md)\n\n<!-- card:start -->\n${"x".repeat(BUDGETS.card + 1)}\n<!-- card:end -->\n`);
  assert.ok(checkDesignDocs(root).some((p) => p.includes("card is") && p.includes("budget")));
  const root2 = treeWithCard();
  write(root2, "docs/design/packs/p.md", `# Pack\n\n> [map](../README.md)\n\n${"y".repeat(BUDGETS.pack + 1)}\n`);
  assert.ok(checkDesignDocs(root2).some((p) => p.includes("p.md: pack is")));
});

test("pack pointers must land on a real file and heading", () => {
  const root = treeWithCard();
  write(root, "docs/design/brand/RULES.md", "# Rules\n\n> [map](../README.md)\n\n## 4. Gates and more\n");
  write(root, "docs/design/packs/p.md", "# Pack\n\n> [map](../README.md)\n\n- `brand/RULES.md#4. Gates`: ok prefix\n");
  assert.deepEqual(checkDesignDocs(root), []);
  write(root, "docs/design/packs/p.md", "# Pack\n\n> [map](../README.md)\n\n- `brand/RULES.md#Nope`: bad\n- `brand/GONE.md#Gates`: bad\n");
  const problems = checkDesignDocs(root);
  assert.ok(problems.some((p) => p.includes('no heading starting "Nope"')));
  assert.ok(problems.some((p) => p.includes("missing file brand/GONE.md")));
});

test("a pack may point into the Spread reference folder", () => {
  const root = treeWithCard();
  write(root, "docs/reference/spread/guide.md", "# Guide\n\n## 3. Layout instructions\n");
  write(root, "docs/design/packs/p.md", "# Pack\n\n> [map](../README.md)\n\n- `../reference/spread/guide.md#3. Layout`: ok\n");
  assert.deepEqual(checkDesignDocs(root), []);
});

test("a long document needs a Summary line", () => {
  const root = healthyTree();
  const filler = "word ".repeat(SUMMARY_OVER_BYTES / 5 + 10);
  write(root, "docs/design/brand/RULES.md", `# Rules\n\n> [map](../README.md)\n\n${filler}\n`);
  assert.ok(checkDesignDocs(root).some((p) => p.includes('no "> Summary:" line')));
  write(root, "docs/design/brand/RULES.md", `# Rules\n\n> [map](../README.md)\n\n> Summary: short.\n\n${filler}\n`);
  assert.deepEqual(checkDesignDocs(root), []);
});

test("a dated spec must be on the specs index, not the map", () => {
  const root = healthyTree();
  write(root, "docs/design/specs/2026-01-01-x.md", "# X\n\n> [map](../README.md)\n");
  assert.ok(checkDesignDocs(root).some((p) => p.includes("not on the specs index")));
  write(root, "docs/design/specs/README.md", "# Specs\n\n> [map](../README.md)\n\n| 2026-01-01 | [X](2026-01-01-x.md) |\n");
  assert.deepEqual(checkDesignDocs(root), []);
});

const HTML = (extra = "") =>
  `<style>\n*{margin:0}\n:root{\n  --oat:#F2EDE4;--paper:#FBF8F1;--ink:#25231F;--soft:#6B6862;--hair:rgba(37,35,31,.12);\n  --olive:#73765F;--olive-deep:#575A44;--clay:#A4623F;--clay-deep:#8F4E2E;\n  --serif:ui-serif,serif;--sans:system-ui,sans-serif;--ease:cubic-bezier(.22,1,.36,1);${extra}\n}\n</style>\n`;

test("tokens.json must match index.html, and a new color without a role is reported", () => {
  const root = healthyTree();
  write(root, "index.html", HTML());
  write(root, "docs/design/tokens.json", renderTokens(root));
  assert.deepEqual(checkDesignDocs(root), []);

  write(root, "index.html", HTML("--oat-two:#EEEEEE;"));
  assert.ok(checkDesignDocs(root).some((p) => p.includes("undocumented color token") && p.includes("--oat-two")));

  write(root, "index.html", HTML());
  write(root, "docs/design/tokens.json", "{}\n");
  assert.ok(checkDesignDocs(root).some((p) => p.includes("tokens.json: stale")));
});
