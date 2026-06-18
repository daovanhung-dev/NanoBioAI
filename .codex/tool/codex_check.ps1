param(
  [switch]$FixFormat,
  [switch]$BuildApk,
  [switch]$BuildRunner,
  [switch]$SkipDoctor
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $ProjectRoot
try {
  if (-not (Test-Path "pubspec.yaml")) {
    throw "pubspec.yaml not found. Run this from a Flutter project root or keep .codex at project root."
  }

  if (-not $SkipDoctor) {
    Write-Host "== flutter doctor -v =="
    flutter doctor -v
  }

  Write-Host "== flutter pub get =="
  flutter pub get

  if ($BuildRunner) {
    Write-Host "== build_runner =="
    dart run build_runner build --delete-conflicting-outputs
  }

  if ($FixFormat) {
    Write-Host "== dart format . =="
    dart format .
  } else {
    Write-Host "== dart format --set-exit-if-changed . =="
    dart format --set-exit-if-changed .
  }

  Write-Host "== flutter analyze =="
  flutter analyze

  Write-Host "== flutter test =="
  flutter test

  if ($BuildApk) {
    Write-Host "== flutter build apk --debug =="
    flutter build apk --debug
  }

  Write-Host "== FULL CHECK PASSED =="
}
finally {
  Pop-Location
}
