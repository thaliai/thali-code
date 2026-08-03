#!/usr/bin/env bash
# Thali Code installer — an AI coding agent for your terminal, wired to Thali.
#
# Safe to run standalone (curl | bash): it downloads what it needs from GitHub
# rather than assuming a checked-out repo.
#
#   curl -fsSL https://raw.githubusercontent.com/thaliai/thali-code/main/install.sh | bash
set -euo pipefail

RAW="https://raw.githubusercontent.com/thaliai/thali-code/main"
TEAL='\033[38;5;43m'; DIM='\033[2m'; BOLD='\033[1m'; RST='\033[0m'
say()  { printf "${TEAL}▪${RST} %s\n" "$1"; }
warn() { printf "  ${DIM}%s${RST}\n" "$1"; }

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CFG="$CFG_DIR/opencode.json"
BIN_DIR="$HOME/.local/bin"
SYNC_DST="$BIN_DIR/thali-sync.mjs"

printf "\n${BOLD}Thali Code${RST} ${DIM}— one API for every model, in your terminal${RST}\n\n"

# 1. engine
if command -v opencode >/dev/null 2>&1; then
  say "Thali Code engine already present."
else
  say "Installing the Thali Code engine…"
  if command -v npm >/dev/null 2>&1; then
    npm install -g opencode-ai --loglevel=error --no-fund --no-audit
  else
    curl -fsSL https://opencode.ai/install | bash
  fi
fi

# 2. Thali configuration (downloaded; never a silent overwrite)
mkdir -p "$CFG_DIR"
if [ -f "$CFG" ]; then
  BAK="$CFG.bak.$(date +%s 2>/dev/null || echo prev)"; cp "$CFG" "$BAK"
  warn "Existing config backed up → $BAK"
fi
curl -fsSL "$RAW/config/opencode.json" -o "$CFG"
say "Thali configuration installed → $CFG"

# 3. model-sync script + the branded command
mkdir -p "$BIN_DIR"
curl -fsSL "$RAW/bin/sync-models.mjs" -o "$SYNC_DST"
curl -fsSL "$RAW/bin/thali" -o "$BIN_DIR/thali"
chmod +x "$BIN_DIR/thali"
rm -f "$BIN_DIR/thali-code"  # superseded by 'thali'
say "Installed the 'thali' command → $BIN_DIR/thali"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "Add to PATH:  export PATH=\"$BIN_DIR:\$PATH\"" ;; esac

# 4. load the live Thali catalog (model listing is public)
if command -v node >/dev/null 2>&1; then
  say "Loading the Thali model catalog…"
  node "$SYNC_DST" || warn "Run 'thali sync' after setting your key to load models."
else
  warn "Node.js 18+ not found — run 'thali sync' later to load all models."
fi

# 5. the key
printf "\n${BOLD}Almost there.${RST}\n"
warn "1. Get your key — 1,000,000 free tokens — at https://thaliai.in"
warn "2. export THALI_API_KEY=thali-sk-…"
warn "3. run:  thali             (use /models to pick any model)"
warn "   later:  thali sync      (refresh the model list any time)"
printf "\n"
