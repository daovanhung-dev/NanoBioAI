param([switch]$FixFormat)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
. (Join-Path $PSScriptRoot "check_helpers.ps1")

Push-Location $ProjectRoot
try {
  if (-not (Test-Path "pubspec.yaml")) { throw "pubspec.yaml not found. Keep .codex at project root." }

  Invoke-NativeCommand -Step "Flutter dependency resolution" -Command "flutter" -Arguments @("pub", "get")
  if ($FixFormat) {
    Invoke-NativeCommand -Step "Dart format write" -Command "dart" -Arguments @("format", ".")
  } else {
    Invoke-NativeCommand -Step "Dart format check" -Command "dart" -Arguments @("format", "--set-exit-if-changed", ".")
  }
  Invoke-NativeCommand -Step "Flutter analyze" -Command "flutter" -Arguments @("analyze")
  Invoke-NativeCommand -Step "Flutter test" -Command "flutter" -Arguments @("test")
  Complete-CodexCheck -Name "QUICK CHECK"
}
catch {
  Write-Error $_
  exit 1
}
finally { Pop-Location }
