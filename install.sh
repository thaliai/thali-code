#!/usr/bin/env bash
# Thali Code installer — OpenCode, wired to Thali (thaliai.in).
#
#   1. installs the OpenCode CLI if needed
#   2. installs the Thali provider config  (~/.config/opencode/opencode.json)
#   3. installs the model-sync script + a `thali-code` command
#   4. syncs the live Thali catalog into the model picker
#
# Thali Code is a Thali-configured distribution of OpenCode (MIT). See NOTICE.
set -euo pipefail

TEAL='\033[38;5;43m'; DIM='\033[2m'; BOLD='\033[1m'; RST='\033[0m'
say()  { printf "${TEAL}▪${RST} %s\n" "$1"; }
warn() { printf "  ${DIM}%s${RST}\n" "$1"; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CFG="$CFG_DIR/opencode.json"
BIN_DIR="$HOME/.local/bin"
SYNC_DST="$BIN_DIR/thali-sync.mjs"

printf "\n${BOLD}Thali Code${RST} ${DIM}— one API for every model, in your terminal${RST}\n\n"

# 1. OpenCode CLI
if command -v opencode >/dev/null 2>&1; then
  say "OpenCode already installed ($(command -v opencode))."
else
  say "Installing OpenCode…"
  if command -v npm >/dev/null 2>&1; then npm install -g opencode-ai
  else curl -fsSL https://opencode.ai/install | bash; fi
fi

# 2. Thali provider config (never a silent overwrite)
mkdir -p "$CFG_DIR"
if [ -f "$CFG" ]; then
  BAK="$CFG.bak.$(date +%s 2>/dev/null || echo prev)"; cp "$CFG" "$BAK"
  warn "Existing config backed up → $BAK"
fi
cp "$HERE/config/opencode.json" "$CFG"
say "Thali provider installed → $CFG"

# 3. sync script + branded command
mkdir -p "$BIN_DIR"
cp "$HERE/bin/sync-models.mjs" "$SYNC_DST"
cp "$HERE/bin/thali-code" "$BIN_DIR/thali-code"
chmod +x "$BIN_DIR/thali-code"
say "Installed 'thali-code' → $BIN_DIR/thali-code"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "Add to PATH:  export PATH=\"$BIN_DIR:\$PATH\"" ;; esac

# 4. populate the model picker from Thali's live catalog (listing is public)
if command -v node >/dev/null 2>&1; then
  say "Syncing the Thali model catalog…"
  node "$SYNC_DST" || warn "Sync skipped — run 'thali-code sync' after setting your key."
else
  warn "Node.js 18+ not found — run 'thali-code sync' later to load all models."
fi

# 5. the key
printf "\n${BOLD}Almost there.${RST}\n"
warn "1. Get your key — 1,000,000 free tokens — at https://thaliai.in"
warn "2. export THALI_API_KEY=thali-sk-…"
warn "3. run:  thali-code        (use /models to pick any model)"
warn "   later:  thali-code sync (refresh the model list any time)"
printf "\n"
