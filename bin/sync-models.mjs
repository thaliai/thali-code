#!/usr/bin/env node
// Sync the Thali catalog into OpenCode's model picker.
//
// Fetches Thali's /v1/models and rewrites the `thali` provider's models map in
// ~/.config/opencode/opencode.json — so every model Thali currently serves
// (Novita-backed and all) shows up under OpenCode's /models picker. Re-run any
// time the catalog changes:  thali-code sync
//
// No dependencies — Node 18+ (built-in fetch). MIT © 2026 Thali Tech Pvt Ltd.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const BASE = process.env.THALI_BASE_URL || "https://thaliai.in/api/v1";
const KEY = process.env.THALI_API_KEY || "";
const CFG_DIR = path.join(
  process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config"),
  "opencode",
);
const CFG = path.join(CFG_DIR, "opencode.json");

// Preferred default coding model, first that exists in the live catalog.
const PREFERRED = [
  "deepseek/deepseek-v3",
  "qwen/qwen3-coder",
  "deepseek/deepseek-r1",
  "anthropic/claude-sonnet-4.6",
];

async function main() {
  let payload;
  try {
    const res = await fetch(`${BASE}/models`, {
      headers: KEY ? { Authorization: `Bearer ${KEY}` } : {},
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    payload = await res.json();
  } catch (e) {
    console.error(`✗ Could not reach Thali at ${BASE}/models — ${e.message}`);
    console.error(`  Check your connection, or THALI_BASE_URL if self-hosting.`);
    process.exit(1);
  }

  const models = {};
  for (const m of payload.data || []) {
    if (m.modality && m.modality !== "chat") continue; // agent needs chat models
    models[m.id] = {
      name: m.id,
      limit: { context: m.context_length || 32768, output: 8192 },
    };
  }
  const count = Object.keys(models).length;
  if (!count) {
    console.error("✗ Thali returned no chat models.");
    process.exit(1);
  }

  // Merge into any existing config, preserving unrelated settings.
  fs.mkdirSync(CFG_DIR, { recursive: true });
  let cfg = {};
  if (fs.existsSync(CFG)) {
    try {
      cfg = JSON.parse(fs.readFileSync(CFG, "utf8"));
    } catch {
      /* malformed — we rewrite it below */
    }
  }
  cfg.$schema = cfg.$schema || "https://opencode.ai/config.json";
  cfg.provider = cfg.provider || {};
  const prev = cfg.provider.thali || {};
  cfg.provider.thali = {
    npm: "@ai-sdk/openai-compatible",
    name: "Thali",
    options: { baseURL: BASE, apiKey: "{env:THALI_API_KEY}" },
    models,
  };

  // Keep a valid default; pick a sensible coding model otherwise.
  const bareDefault = (cfg.model || "").replace(/^thali\//, "");
  if (!cfg.model || !models[bareDefault]) {
    const pick = PREFERRED.find((s) => models[s]) || Object.keys(models)[0];
    cfg.model = `thali/${pick}`;
  }

  fs.writeFileSync(CFG, JSON.stringify(cfg, null, 2) + "\n");
  console.log(`✓ Synced ${count} Thali models → ${CFG}`);
  console.log(`  Default model: ${cfg.model}`);
  console.log(`  Run 'thali-code' and use the /models picker to switch.`);
  void prev;
}

main();
