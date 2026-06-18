$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $ProjectRoot
try {
  $targets = @("AGENTS.md", "README_CODEX.md", "docs\codex", "tool\codex_check.ps1", "tool\codex_check.sh", "tool\codex_quick_check.ps1", "tool\codex_quick_check.sh")
  foreach ($target in $targets) {
    if (Test-Path $target) {
      Write-Host "Removing old Codex layout item: $target"
      Remove-Item $target -Recurse -Force
    }
  }
  Write-Host "Old Codex layout cleanup completed. Current pack lives in .codex/."
}
finally {
  Pop-Location
}
