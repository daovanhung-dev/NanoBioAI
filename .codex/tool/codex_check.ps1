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
  if (-not (Test-Path "pubspec.yaml")) { throw "pubspec.yaml not found. Keep .codex at project root." }

  if (-not $SkipDoctor) { flutter doctor -v }
  flutter pub get
  if ($BuildRunner) { dart run build_runner build --delete-conflicting-outputs }
  if ($FixFormat) { dart format . } else { dart format --set-exit-if-changed . }
  flutter analyze
  flutter test
  if ($BuildApk) { flutter build apk --debug }
  Write-Host "FULL CHECK PASSED"
}
finally { Pop-Location }
