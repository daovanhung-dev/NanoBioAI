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
source "$SCRIPT_DIR/check_helpers.sh"
cd "$PROJECT_ROOT"

[[ -f pubspec.yaml ]] || { echo "pubspec.yaml not found. Keep .codex at project root." >&2; exit 1; }

invoke_native_command "Flutter dependency resolution" flutter pub get
if [[ "$FIX_FORMAT" == "1" ]]; then
  invoke_native_command "Dart format write" dart format .
else
  invoke_native_command "Dart format check" dart format --set-exit-if-changed .
fi
invoke_native_command "Flutter analyze" flutter analyze
invoke_native_command "Flutter test" flutter test

complete_codex_check "QUICK CHECK"
