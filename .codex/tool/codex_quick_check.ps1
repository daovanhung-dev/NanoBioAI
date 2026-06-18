param(
  [switch]$FixFormat
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $ProjectRoot
try {
  if (-not (Test-Path "pubspec.yaml")) {
    throw "pubspec.yaml not found. Run this from a Flutter project root or keep .codex at project root."
  }

  Write-Host "== flutter pub get =="
  flutter pub get

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

  Write-Host "== QUICK CHECK PASSED =="
}
finally {
  Pop-Location
}
