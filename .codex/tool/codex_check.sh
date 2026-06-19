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
cd "$PROJECT_ROOT"

[[ -f pubspec.yaml ]] || { echo "pubspec.yaml not found. Keep .codex at project root." >&2; exit 1; }

[[ "$SKIP_DOCTOR" == "1" ]] || flutter doctor -v
flutter pub get
[[ "$BUILD_RUNNER" == "1" ]] && dart run build_runner build --delete-conflicting-outputs
if [[ "$FIX_FORMAT" == "1" ]]; then
  dart format .
else
  dart format --set-exit-if-changed .
fi
flutter analyze
flutter test
[[ "$BUILD_APK" == "1" ]] && flutter build apk --debug

echo "FULL CHECK PASSED"
