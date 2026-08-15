param(
    [Parameter(Position = 0)]
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $ProjectRoot).Path
Push-Location $root
try {
    Write-Host "== Dart/Flutter analyzer refresh helper =="
    $dartVersion = (& dart --version 2>&1 | Out-String).Trim()
    $flutterVersion = (& flutter --version 2>&1 | Select-Object -First 1 | Out-String).Trim()
    Write-Host $flutterVersion
    Write-Host $dartVersion
    Write-Host ""
    Write-Host "Refreshing package configuration..."
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
    Write-Host ""
    Write-Host "Next in VS Code:"
    Write-Host "  1. Ctrl+Shift+P -> Dart: Restart Analysis Server"
    Write-Host "  2. If stale diagnostics remain: Developer: Reload Window"
    Write-Host "  3. Re-run: flutter analyze"
    Write-Host ""
    Write-Host "Do not add ignore comments for ordinary RegExp(...) usage merely to silence the stale LSP diagnostic."
}
finally {
    Pop-Location
}
