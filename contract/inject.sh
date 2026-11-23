#!/usr/bin/env bash
# Writes the working contract into a repo's instruction file (AGENTS.md).
# Usage: contract/inject.sh <target-file> [contract-file]
# The contract carries its own start and end markers. A target that already has
# the block gets it replaced; one without it gets the block after its first heading.
set -euo pipefail

TARGET="${1:?target file}"
CONTRACT="${2:-$(dirname "$0")/CONTRACT.md}"
START='<!-- contract:start'
END='<!-- contract:end -->'

[ -f "$TARGET" ] || { echo "inject: $TARGET não existe" >&2; exit 1; }
grep -qF "$START" "$CONTRACT" && grep -qF "$END" "$CONTRACT" || { echo "inject: $CONTRACT sem os marcadores" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if grep -qF "$START" "$TARGET"; then
  grep -qF "$END" "$TARGET" || { echo "inject: $TARGET tem o início do bloco e não tem o fim" >&2; exit 1; }
  awk -v start="$START" -v end="$END" -v contract="$CONTRACT" '
    index($0, start) == 1 { while ((getline line < contract) > 0) print line; skipping = 1; next }
    skipping && index($0, end) == 1 { skipping = 0; next }
    !skipping { print }
  ' "$TARGET" > "$TMP"
else
  awk -v contract="$CONTRACT" '
    { print }
    !done && /^# / { print ""; while ((getline line < contract) > 0) print line; done = 1 }
  ' "$TARGET" > "$TMP"
  grep -qF "$START" "$TMP" || { echo "inject: $TARGET não tem um título de nível 1 para ancorar o bloco" >&2; exit 1; }
fi

cat "$TMP" > "$TARGET"
