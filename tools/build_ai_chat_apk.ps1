[CmdletBinding()]
param(
    [string]$EntryPoint = "lib/main.dart",
    [string]$EnvFile = ".env",
    [ValidateSet("debug", "profile", "release")]
    [string]$Mode = "debug"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DefinesFile = ".dart_tool/nanobio_defines.json"

& (Join-Path $PSScriptRoot "prepare_dart_defines.ps1") `
    -EnvFile $EnvFile `
    -OutputFile $DefinesFile

$flutterArgs = @(
    "build", "apk",
    "-t", $EntryPoint,
    "--$Mode",
    "--dart-define-from-file=$DefinesFile"
)

Push-Location $ProjectRoot
try {
    & flutter @flutterArgs
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build apk thất bại với exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
