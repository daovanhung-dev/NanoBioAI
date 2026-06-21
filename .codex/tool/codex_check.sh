#!/usr/bin/env bash
set -euo pipefail

FIX_FORMAT=0; BUILD_APK=0; BUILD_RUNNER=0; SKIP_DOCTOR=0
for arg in "$@"; do
  case "$arg" in
    --fix-format) FIX_FORMAT=1 ;;
    --build-apk) BUILD_APK=1 ;;
    --build-runner) BUILD_RUNNER=1 ;;
    --skip-doctor) SKIP_DOCTOR=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check_helpers.sh"
cd "$PROJECT_ROOT"

[[ -f pubspec.yaml ]] || { echo "pubspec.yaml not found. Keep .codex at project root." >&2; exit 1; }

if [[ "$SKIP_DOCTOR" == "1" ]]; then
  add_codex_skipped_step "Flutter doctor" "skip-doctor argument was provided."
else
  invoke_native_command "Flutter doctor" flutter doctor -v
fi
invoke_native_command "Flutter dependency resolution" flutter pub get
[[ "$BUILD_RUNNER" == "1" ]] && invoke_native_command "Dart build_runner" dart run build_runner build --delete-conflicting-outputs
if [[ "$FIX_FORMAT" == "1" ]]; then
  invoke_native_command "Dart format write" dart format .
else
  invoke_native_command "Dart format check" dart format --set-exit-if-changed .
fi
invoke_native_command "Flutter analyze" flutter analyze
invoke_native_command "Flutter test" flutter test
[[ "$BUILD_APK" == "1" ]] && invoke_native_command "Flutter debug APK build" flutter build apk --debug

complete_codex_check "FULL CHECK"
