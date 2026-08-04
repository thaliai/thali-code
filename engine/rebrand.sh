#!/usr/bin/env bash
# Thali Code — rebrand the OpenCode engine's USER-VISIBLE text.
#
# Runs against a checked-out engine tree before building. It rewrites only
# display strings a Thali customer would see; it never touches:
#   - code identifiers (OpenCodeHttpApi, OpenCodeError — "OpenCode" + a letter)
#   - the provider id "opencode" (load-bearing for free-model routing)
#   - imports, package names, or the opencode.ai / github.com/sst/opencode URLs
#   - OpenAI / OpenRouter / OpenTUI / OpenAuth (unrelated brands)
#   - the OpenCode attribution in NOTICE
# Idempotent — running it twice is a no-op.
set -euo pipefail

ENGINE_DIR="${1:?usage: rebrand.sh <engine-dir>}"
command -v perl >/dev/null 2>&1 || { echo "rebrand.sh needs perl"; exit 1; }

# The display-string rewrites, applied to every user-facing source file.
#  1. "OpenCode" as a word -> "Thali Code". The negative lookahead (?![A-Za-z])
#     leaves OpenCodeHttpApi / OpenCodeError (identifiers) untouched; we verified
#     no OpenCode.<call> / OpenCode(...) code use exists in the scoped tree.
#  2. Command hints the user would type — the command is now `thali`, so
#     `opencode models` etc. are both off-brand AND wrong. The trailing subcommand
#     word is required, so the quoted provider id "opencode" (quote follows, no
#     space) is never matched.
read -r -d '' PERL <<'PL' || true
s/OpenCode(?![A-Za-z])/Thali Code/g;
s/\bopencode (--mini|--help|--continue|models|auth|serve|server|session|upgrade|api|tui|run|agent|debug)\b/thali $1/g;
s/\bopencode is installed\b/thali is installed/g;
PL

# Scope: the TUI, the user-facing CLI, and the one retry message that promotes a
# paid tier. -print0/xargs keeps it working with odd paths and on macOS bash 3.2.
find "$ENGINE_DIR/packages/tui/src" "$ENGINE_DIR/packages/opencode/src/cli" \
     -type f \( -name '*.ts' -o -name '*.tsx' \) ! -name '*.test.ts' -print0 \
  | xargs -0 perl -0777 -pi -e "$PERL"
perl -0777 -pi -e "$PERL" "$ENGINE_DIR/packages/opencode/src/session/retry.ts" 2>/dev/null || true

# CLI program name shown in `thali --help` usage.
perl -pi -e 's/\.scriptName\("opencode"\)/.scriptName("thali")/g' \
  "$ENGINE_DIR/packages/opencode/src/index.ts" \
  "$ENGINE_DIR/packages/opencode/src/temporary.ts" 2>/dev/null || true

# Default terminal-tab title (lowercase constant, not caught above).
perl -pi -e 's/const DEFAULT_TITLE = "opencode"/const DEFAULT_TITLE = "Thali Code"/' \
  "$ENGINE_DIR/packages/tui/src/attention.ts" 2>/dev/null || true

# Suppress OpenCode's paid Zen/Go upsell entirely: empty the provider set that
# gates the Go-upsell UI, so it never renders (the connect-dialog Zen/Go promos
# are already gone via disabled_providers in the Thali config).
perl -pi -e 's/const GO_UPSELL_PROVIDERS = new Set\(\["opencode", "opencode-go"\]\)/const GO_UPSELL_PROVIDERS = new Set([])/' \
  "$ENGINE_DIR/packages/tui/src/routes/session/index.tsx" 2>/dev/null || true

# Drop the rotating home-screen tips that promote OpenCode-only services/infra
# which don't exist for Thali: the Zen curated-models tip, the OpenCode GitHub
# app, the OpenCode container image, and the opencode.ai share link. (Tips that
# name real engine paths like .opencode/ or opencode.json are left — they are
# accurate and functional for the engine Thali runs.)
perl -ni -e '
  print unless
    /Thali Code Zen for curated/ ||
    m{ghcr\.io/anomalyco} ||
    m{/opencode\{/highlight\} in GitHub} ||
    /opencode github install/ ||
    m{/opencode fix this} ||
    /public opencode\.ai link/;
' "$ENGINE_DIR/packages/tui/src/feature-plugins/home/tips-view.tsx" 2>/dev/null || true

echo "rebrand: user-visible OpenCode -> Thali Code applied"
