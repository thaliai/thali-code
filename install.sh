#!/usr/bin/env bash
# Thali Code installer — sets up OpenCode pointed at Thali (thaliai.in).
#
# What it does, in order:
#   1. installs the OpenCode CLI if it isn't already present
#   2. installs the Thali provider config to ~/.config/opencode/opencode.json
#      (backing up any existing config first — never a silent overwrite)
#   3. drops a `thali-code` command that runs OpenCode
#   4. tells you how to set your Thali API key
#
# Thali Code is a Thali-configured distribution of OpenCode (MIT). See NOTICE.
set -euo pipefail

TEAL='\033[38;5;43m'; DIM='\033[2m'; BOLD='\033[1m'; RST='\033[0m'
say() { printf "${TEAL}▪${RST} %s\n" "$1"; }
warn() { printf "  ${DIM}%s${RST}\n" "$1"; }

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG="$CONFIG_DIR/opencode.json"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config/opencode.json"

printf "\n${BOLD}Thali Code${RST} ${DIM}— one API for every model, in your terminal${RST}\n\n"

# 1. OpenCode CLI
if command -v opencode >/dev/null 2>&1; then
  say "OpenCode is already installed ($(command -v opencode))."
else
  say "Installing OpenCode…"
  if command -v npm >/dev/null 2>&1; then
    npm install -g opencode-ai
  else
    curl -fsSL https://opencode.ai/install | bash
  fi
fi

# 2. Thali provider config (safe: back up anything already there)
mkdir -p "$CONFIG_DIR"
if [ -f "$CONFIG" ]; then
  BAK="$CONFIG.bak.$(date +%s 2>/dev/null || echo prev)"
  cp "$CONFIG" "$BAK"
  warn "Existing config backed up to $BAK"
fi
cp "$SRC" "$CONFIG"
say "Thali provider installed → $CONFIG"

# 3. branded `thali-code` command
BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/thali-code" <<'WRAP'
#!/usr/bin/env bash
# Thali Code — OpenCode, pointed at Thali.
if [ -z "${THALI_API_KEY:-}" ]; then
  echo "Set your Thali API key first:  export THALI_API_KEY=thali-sk-…"
  echo "Get one free (1,000,000 tokens) at https://thaliai.in"
  exit 1
fi
exec opencode "$@"
WRAP
chmod +x "$BIN_DIR/thali-code"
say "Installed the 'thali-code' command → $BIN_DIR/thali-code"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "Add to PATH:  export PATH=\"$BIN_DIR:\$PATH\"" ;; esac

# 4. the key
printf "\n${BOLD}Almost there.${RST}\n"
warn "1. Get your Thali API key (1,000,000 free tokens): https://thaliai.in"
warn "2. export THALI_API_KEY=thali-sk-…"
warn "3. cd into a project and run:  thali-code"
printf "\n"
