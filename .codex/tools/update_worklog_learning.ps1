param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
)

$ErrorActionPreference = "Stop"
$python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -eq $python) {
  $python = Get-Command python -ErrorAction SilentlyContinue
}
if ($null -eq $python) {
  throw "Python 3 is required to refresh worklog learning."
}

& $python.Source `
  (Join-Path $PSScriptRoot "update_worklog_learning.py") `
  --project-root $ProjectRoot `
  --write

if ($LASTEXITCODE -ne 0) {
  throw "Worklog learning refresh failed with exit code $LASTEXITCODE."
}
