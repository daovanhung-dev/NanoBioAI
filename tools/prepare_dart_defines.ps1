[CmdletBinding()]
param(
  [string]$EnvFile = ".env",
  [string]$OutputFile = ".dart_tool/nanobio_defines.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$sourcePath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $EnvFile))
$outputPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputFile))

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
  throw "Environment file was not found: $EnvFile"
}

$values = [ordered]@{}
foreach ($line in [System.IO.File]::ReadAllLines($sourcePath)) {
  $candidate = $line.Trim()
  if ([string]::IsNullOrWhiteSpace($candidate) -or $candidate.StartsWith("#")) { continue }
  if ($candidate.StartsWith("export ", [System.StringComparison]::OrdinalIgnoreCase)) {
    $candidate = $candidate.Substring(7).TrimStart()
  }
  $separatorIndex = $candidate.IndexOf("=")
  if ($separatorIndex -le 0) { continue }
  $key = $candidate.Substring(0, $separatorIndex).Trim().TrimStart([char]0xFEFF)
  $value = $candidate.Substring($separatorIndex + 1).Trim()
  if ($value.Length -ge 2 -and (($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') -or ($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'"))) {
    $value = $value.Substring(1, $value.Length - 2).Trim()
  }
  if (-not [string]::IsNullOrWhiteSpace($value)) { $values[$key] = $value }
}

$required = @("SUPABASE_URL", "SUPABASE_ANON_KEY", "AUTH_EMAIL_REDIRECT_URL", "GEMINI_API_KEY")
$missing = @($required | Where-Object { -not $values.Contains($_) })
if ($missing.Count -gt 0) { throw "Environment validation failed for: $($missing -join ', ')" }

$parent = Split-Path -Parent $outputPath
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$values | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $outputPath -Encoding UTF8
Write-Host "Dart defines prepared in .dart_tool without printing secret values."
