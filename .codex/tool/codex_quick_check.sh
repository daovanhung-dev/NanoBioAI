#!/usr/bin/env bash
set -euo pipefail

FIX_FORMAT=0
for arg in "$@"; do
  case "$arg" in
    --fix-format) FIX_FORMAT=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

[[ -f pubspec.yaml ]] || { echo "pubspec.yaml not found. Keep .codex at project root." >&2; exit 1; }

flutter pub get
if [[ "$FIX_FORMAT" == "1" ]]; then
  dart format .
else
  dart format --set-exit-if-changed .
fi
flutter analyze
flutter test

echo "QUICK CHECK PASSED"
