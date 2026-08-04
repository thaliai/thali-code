#!/usr/bin/env bash
# Thali Code installer — an AI coding agent for your terminal, wired to Thali.
#
# Thali Code builds the open-source OpenCode engine — with Thali's own branding
# and provider config — into a standalone binary. Safe to run via:
#   curl -fsSL https://raw.githubusercontent.com/thaliai/thali-code/main/install.sh | bash
#
# First run fetches the engine, installs deps, and compiles it — a few minutes.
# Later runs rebuild it. See NOTICE for OpenCode attribution (MIT).
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

# 2. the engine — pinned to the exact OpenCode commit Thali validated (patched
#    logo + Solid-plugin build). Bump OPENCODE_COMMIT to adopt a newer OpenCode.
OPENCODE_COMMIT="9535a8f929eeeb4116f3d06d2a8391e0ec72cff5"
say "Fetching the Thali Code engine (first run takes a few minutes)…"
mkdir -p "$ENGINE_DIR"
if [ ! -d "$ENGINE_DIR/.git" ]; then
  git -C "$ENGINE_DIR" init -q
  git -C "$ENGINE_DIR" remote add origin https://github.com/sst/opencode >/dev/null 2>&1 || true
fi
git -C "$ENGINE_DIR" fetch -q --depth 1 origin "$OPENCODE_COMMIT"
git -C "$ENGINE_DIR" checkout -q -f FETCH_HEAD

# 3. apply Thali branding — the THALI CODE splash (teal) + user-visible text
curl -fsSL "$RAW/engine/logo.ts"    -o "$ENGINE_DIR/packages/tui/src/logo.ts"
curl -fsSL "$RAW/engine/logo.tsx"   -o "$ENGINE_DIR/packages/tui/src/component/logo.tsx"
# The exit screen keeps its OWN private wordmark, separate from logo.ts -- patching
# logo.ts alone still showed "opencode" on quit.
curl -fsSL "$RAW/engine/presentation.ts" -o "$ENGINE_DIR/packages/tui/src/util/presentation.ts"
curl -fsSL "$RAW/engine/rebrand.sh" -o "$ENGINE_DIR/.thali-rebrand.sh"
bash "$ENGINE_DIR/.thali-rebrand.sh" "$ENGINE_DIR" >/dev/null
say "Applied Thali Code branding."

# 4. dependencies + build the branded binary (bakes the THALI CODE splash in, and
#    sidesteps the JSX/worker setup that running from source would need)
( cd "$ENGINE_DIR" && bun install >/dev/null 2>&1 )
say "Building Thali Code (the slow part — a few minutes)…"
( cd "$ENGINE_DIR/packages/opencode" && bun run script/build.ts --single --skip-embed-web-ui >/dev/null 2>&1 )
BIN=$(ls "$ENGINE_DIR/packages/opencode/dist"/opencode-*/bin/opencode 2>/dev/null | head -1)
if [ -z "$BIN" ] || [ ! -x "$BIN" ]; then
  printf "  ${DIM}Build failed. Please report at github.com/thaliai/thali-code/issues${RST}\n"; exit 1
fi
say "Thali Code built."

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
