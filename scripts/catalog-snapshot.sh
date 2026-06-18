#!/usr/bin/env bash
# Catalog drift detector — snapshots the live model catalog so future runs can diff
# against it to spot new models, retirements, price/context changes.
#
#   bash scripts/catalog-snapshot.sh                 # write evidence/<date>-catalog.txt
#   bash scripts/catalog-snapshot.sh --diff          # diff newest two snapshots
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p evidence

if [ "${1:-}" = "--diff" ]; then
  mapfile -t snaps < <(ls -1 evidence/*-catalog.txt 2>/dev/null | sort | tail -2)
  [ "${#snaps[@]}" -eq 2 ] || { echo "need >=2 snapshots to diff"; exit 1; }
  echo "diff ${snaps[0]}  ->  ${snaps[1]}"
  diff "${snaps[0]}" "${snaps[1]}" || true
  exit 0
fi

command -v gjc >/dev/null 2>&1 || { echo "gjc not found"; exit 2; }
DATE="$(date +%Y-%m-%d)"; OUT="evidence/${DATE}-catalog.txt"
# Per-provider model listing GJC currently resolves (bundled + live-discovered after /login).
: > "$OUT"
for q in claude-opus claude-sonnet claude-haiku gpt-5 grok gemini deepseek glm kimi qwen mimo minimax; do
  echo "## query: $q" >> "$OUT"
  gjc --list-models "$q" 2>/dev/null | grep -vE '^\s*$' >> "$OUT" || true
  echo >> "$OUT"
done
echo "Wrote $OUT ($(wc -l <"$OUT") lines). Run with --diff to compare snapshots."
