param([switch]$FixFormat)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $ProjectRoot
try {
  if (-not (Test-Path "pubspec.yaml")) { throw "pubspec.yaml not found. Keep .codex at project root." }

  flutter pub get
  if ($FixFormat) { dart format . } else { dart format --set-exit-if-changed . }
  flutter analyze
  flutter test
  Write-Host "QUICK CHECK PASSED"
}
finally { Pop-Location }
