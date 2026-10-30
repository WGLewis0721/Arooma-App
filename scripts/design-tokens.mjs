// Generates docs/design/tokens.json from the :root block in index.html so agents read the design
// tokens as data (a few hundred bytes) instead of reading CSS or prose. index.html stays the single
// source of truth; scripts/design-docs.test.mjs and `npm run docs:check` fail if tokens.json is stale.
// It also fails when a color token exists in :root without a documented role, which enforces the
// "no new colors" rule: add the token to TOKEN_ROLES (and the brand board) in the same change.
//
//   node scripts/design-tokens.mjs --write   regenerate docs/design/tokens.json
//   node scripts/design-tokens.mjs           print it
//
// Forked from the Spread design brain (spread-app 4c23d25) and adapted for Arooma.
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

// What each token is for. Source: docs/design/brand/BRAND_BOARD.md, section 1.
export const TOKEN_ROLES = {
  "--oat": "app ground (background)",
  "--paper": "card surface: opaque, never glass",
  "--ink": "primary text, primary buttons, icon silhouette",
  "--soft": "secondary text",
  "--hair": "hairlines",
  "--olive": "secondary: daily pick outline and graphics; graphics and large text only",
  "--olive-deep": "small labels and the Today's pick tab",
  "--clay": "accent: low-stock gauge and graphics; graphics and large text only",
  "--clay-deep": "small low-stock text",
};

function block(source, header) {
  const start = source.indexOf(header);
  if (start < 0) throw new Error(`design-tokens: ${header} not found in index.html`);
  const open = source.indexOf("{", start);
  let depth = 0;
  for (let i = open; i < source.length; i += 1) {
    if (source[i] === "{") depth += 1;
    if (source[i] === "}") {
      depth -= 1;
      if (depth === 0) return source.slice(open + 1, i);
    }
  }
  throw new Error(`design-tokens: unterminated block ${header}`);
}

function declarations(body) {
  const out = {};
  for (const m of body.matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)) out[m[1]] = m[2].trim().replace(/\s+/g, " ");
  return out;
}

const isColor = (value) => /^(#|rgba?\(|hsla?\()/i.test(value);

export function buildTokens(html) {
  const all = declarations(block(html, ":root{"));
  const undocumented = Object.entries(all).filter(([k, v]) => isColor(v) && !(k in TOKEN_ROLES)).map(([k]) => k);
  if (undocumented.length) {
    throw new Error(`design-tokens: undocumented color token(s) in :root: ${undocumented.join(", ")}. Add a role in scripts/design-tokens.mjs and the brand board first.`);
  }
  const missing = Object.keys(TOKEN_ROLES).filter((k) => !(k in all));
  if (missing.length) throw new Error(`design-tokens: token(s) documented but missing from :root: ${missing.join(", ")}`);

  const light = Object.fromEntries(Object.keys(TOKEN_ROLES).map((k) => [k, all[k]]));
  return {
    note: "Generated from the :root block in index.html by scripts/design-tokens.mjs. Do not edit by hand. Use tokens, never raw values.",
    modes: "V2 four luxury themes plus light/dark appearance, legacy :root tokens kept for neutral bottle artwork",
    roles: TOKEN_ROLES,
    light,
    fonts: { display: all["--serif"], ui: all["--sans"] },
    ease: all["--ease"],
    night: {
      status: "implemented via V2 themed dark appearance; these five values remain historical V1 reference",
      ground: "#1C1B18",
      card: "#26241F",
      text: "#EDE7DB",
      olive: "#A9AC8F",
      clay: "#D79470",
    },
    runtimeVars: "--cw, --ch, --u and --plank are set by the script from the shelf size. They are layout, not design tokens.",
  };
}

export function renderTokens(root) {
  return `${JSON.stringify(buildTokens(readFileSync(join(root, "index.html"), "utf8")), null, 2)}\n`;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const out = renderTokens(process.cwd());
  if (process.argv.includes("--write")) {
    writeFileSync(join(process.cwd(), "docs/design/tokens.json"), out);
    console.error("design-tokens: wrote docs/design/tokens.json");
  } else process.stdout.write(out);
}
