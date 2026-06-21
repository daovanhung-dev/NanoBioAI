param(
  [switch]$FixFormat,
  [switch]$BuildApk,
  [switch]$BuildRunner,
  [switch]$SkipDoctor
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
. (Join-Path $PSScriptRoot "check_helpers.ps1")

Push-Location $ProjectRoot
try {
  if (-not (Test-Path "pubspec.yaml")) { throw "pubspec.yaml not found. Keep .codex at project root." }

  if (-not $SkipDoctor) {
    Invoke-NativeCommand -Step "Flutter doctor" -Command "flutter" -Arguments @("doctor", "-v")
  } else {
    Add-CodexSkippedStep -Step "Flutter doctor" -Reason "SkipDoctor switch was provided."
  }
  Invoke-NativeCommand -Step "Flutter dependency resolution" -Command "flutter" -Arguments @("pub", "get")
  if ($BuildRunner) {
    Invoke-NativeCommand -Step "Dart build_runner" -Command "dart" -Arguments @("run", "build_runner", "build", "--delete-conflicting-outputs")
  }
  if ($FixFormat) {
    Invoke-NativeCommand -Step "Dart format write" -Command "dart" -Arguments @("format", ".")
  } else {
    Invoke-NativeCommand -Step "Dart format check" -Command "dart" -Arguments @("format", "--set-exit-if-changed", ".")
  }
  Invoke-NativeCommand -Step "Flutter analyze" -Command "flutter" -Arguments @("analyze")
  Invoke-NativeCommand -Step "Flutter test" -Command "flutter" -Arguments @("test")
  if ($BuildApk) {
    Invoke-NativeCommand -Step "Flutter debug APK build" -Command "flutter" -Arguments @("build", "apk", "--debug")
  }
  Complete-CodexCheck -Name "FULL CHECK"
}
catch {
  Write-Error $_
  exit 1
}
finally { Pop-Location }
