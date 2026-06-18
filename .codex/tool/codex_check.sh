#!/usr/bin/env bash
set -euo pipefail

FIX_FORMAT=0
BUILD_APK=0
BUILD_RUNNER=0
SKIP_DOCTOR=0

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

if [[ ! -f pubspec.yaml ]]; then
  echo "pubspec.yaml not found. Run this from a Flutter project root or keep .codex at project root." >&2
  exit 1
fi

if [[ "$SKIP_DOCTOR" != "1" ]]; then
  echo "== flutter doctor -v =="
  flutter doctor -v
fi

echo "== flutter pub get =="
flutter pub get

if [[ "$BUILD_RUNNER" == "1" ]]; then
  echo "== build_runner =="
  dart run build_runner build --delete-conflicting-outputs
fi

if [[ "$FIX_FORMAT" == "1" ]]; then
  echo "== dart format . =="
  dart format .
else
  echo "== dart format --set-exit-if-changed . =="
  dart format --set-exit-if-changed .
fi

echo "== flutter analyze =="
flutter analyze

echo "== flutter test =="
flutter test

if [[ "$BUILD_APK" == "1" ]]; then
  echo "== flutter build apk --debug =="
  flutter build apk --debug
fi

echo "== FULL CHECK PASSED =="
