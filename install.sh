#!/usr/bin/env bash
# Thali Code installer — an AI coding agent for your terminal, wired to Thali.
#
# Thali Code runs the open-source OpenCode engine from source, with Thali's own
# branding and provider config. Safe to run via:
#   curl -fsSL https://raw.githubusercontent.com/thaliai/thali-code/main/install.sh | bash
#
# First run clones the engine and installs its dependencies — that takes a few
# minutes. Later runs update it. See NOTICE for OpenCode attribution (MIT).
set -euo pipefail

RAW="https://raw.githubusercontent.com/thaliai/thali-code/main"
ENGINE_DIR="$HOME/.thali-code/engine"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CFG="$CFG_DIR/opencode.json"
BIN_DIR="$HOME/.local/bin"
SYNC_DST="$BIN_DIR/thali-sync.mjs"

TEAL='\033[38;5;43m'; DIM='\033[2m'; BOLD='\033[1m'; RST='\033[0m'
say()  { printf "${TEAL}▪${RST} %s\n" "$1"; }
warn() { printf "  ${DIM}%s${RST}\n" "$1"; }

printf "\n${BOLD}Thali Code${RST} ${DIM}— one API for every model, in your terminal${RST}\n\n"

# 1. Bun (the runtime the engine runs on)
if ! command -v bun >/dev/null 2>&1; then
  say "Installing Bun (the Thali Code runtime)…"
  curl -fsSL https://bun.sh/install | bash >/dev/null
fi
export PATH="$HOME/.bun/bin:$PATH"

# 2. the engine — clone or update
say "Fetching the Thali Code engine (first run takes a few minutes)…"
if [ -d "$ENGINE_DIR/.git" ]; then
  git -C "$ENGINE_DIR" pull --ff-only >/dev/null 2>&1 || true
else
  mkdir -p "$(dirname "$ENGINE_DIR")"
  git clone --depth 1 https://github.com/sst/opencode "$ENGINE_DIR" >/dev/null 2>&1
fi

# 3. apply Thali branding (the THALI CODE splash, in teal)
curl -fsSL "$RAW/engine/logo.ts"  -o "$ENGINE_DIR/packages/tui/src/logo.ts"
curl -fsSL "$RAW/engine/logo.tsx" -o "$ENGINE_DIR/packages/tui/src/component/logo.tsx"
say "Applied Thali Code branding."

# 4. dependencies
( cd "$ENGINE_DIR" && bun install >/dev/null 2>&1 )
say "Engine ready."

# 5. Thali provider config (never a silent overwrite)
mkdir -p "$CFG_DIR"
if [ -f "$CFG" ]; then
  BAK="$CFG.bak.$(date +%s 2>/dev/null || echo prev)"; cp "$CFG" "$BAK"
  warn "Existing config backed up → $BAK"
fi
curl -fsSL "$RAW/config/opencode.json" -o "$CFG"

# 6. model-sync + the branded command
mkdir -p "$BIN_DIR"
curl -fsSL "$RAW/bin/sync-models.mjs" -o "$SYNC_DST"
curl -fsSL "$RAW/bin/thali" -o "$BIN_DIR/thali"
chmod +x "$BIN_DIR/thali"
rm -f "$BIN_DIR/thali-code"  # superseded by 'thali'
say "Installed the 'thali' command → $BIN_DIR/thali"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "Add to PATH:  export PATH=\"$BIN_DIR:\$PATH\"" ;; esac

# 7. load the live Thali catalog (public)
if command -v node >/dev/null 2>&1; then node "$SYNC_DST" >/dev/null 2>&1 || true; fi

printf "\n${BOLD}Done.${RST}\n"
warn "1. Get your key — 1,000,000 free tokens — at https://thaliai.in"
warn "2. export THALI_API_KEY=thali-sk-…"
warn "3. run:  thali"
printf "\n"
