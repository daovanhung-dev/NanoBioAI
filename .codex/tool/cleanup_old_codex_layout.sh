#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

for target in AGENTS.md README_CODEX.md docs/codex tool/codex_check.ps1 tool/codex_check.sh tool/codex_quick_check.ps1 tool/codex_quick_check.sh; do
  if [[ -e "$target" ]]; then
    echo "Removing old Codex layout item: $target"
    rm -rf "$target"
  fi
done

echo "Old Codex layout cleanup completed. Current pack lives in .codex/."
