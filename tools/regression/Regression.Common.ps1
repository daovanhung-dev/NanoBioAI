Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RegressionRepoRoot = [System.IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot "../..")
)
$script:RegressionEvidenceRoot = [System.IO.Path]::GetFullPath(
  (Join-Path $script:RegressionRepoRoot "docs/test/v2-admin-regression")
)
$script:RegressionMatrixPath = Join-Path $script:RegressionEvidenceRoot `
  "001-test-v2-admin-regression.md"
$script:RegressionPackageName = "com.example.nano_app"

function Assert-RegressionPathInsideRoot {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Root
  )

  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  )
  $prefix = $resolvedRoot + [System.IO.Path]::DirectorySeparatorChar
  if (
    -not $resolvedPath.Equals(
      $resolvedRoot,
      [System.StringComparison]::OrdinalIgnoreCase
    ) -and
    -not $resolvedPath.StartsWith(
      $prefix,
      [System.StringComparison]::OrdinalIgnoreCase
    )
  ) {
    throw "Path is outside the allowed root."
  }
  return $resolvedPath
}

function Resolve-RegressionRepoFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
    $Path
  } else {
    Join-Path $script:RegressionRepoRoot $Path
  }
  $resolved = Assert-RegressionPathInsideRoot `
    -Path $candidate `
    -Root $script:RegressionRepoRoot
  if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "$Label file was not found."
  }
  return $resolved
}

function Get-RegressionCases {
  if (-not (Test-Path -LiteralPath $script:RegressionMatrixPath -PathType Leaf)) {
    throw "Regression matrix was not found."
  }

  $cases = New-Object System.Collections.Generic.List[object]
  foreach ($line in [System.IO.File]::ReadAllLines($script:RegressionMatrixPath)) {
    if ($line -notmatch '^\|\s*((PRE|V2|ADM|AUT)-[A-Z0-9-]+)\s*\|') {
      continue
    }
    $cells = @($line.Split('|') | ForEach-Object { $_.Trim() })
    if ($cells.Count -lt 9) {
      throw "Malformed regression matrix row for $($Matches[1])."
    }
    $cases.Add([pscustomobject]@{
      CaseId = $cells[1]
      Persona = $cells[2]
      Scenario = $cells[3]
      BdRefs = $cells[4]
      AssetPath = ($cells[5] -replace '`', '')
      EvidencePath = ($cells[6] -replace '`', '')
      Status = $cells[7]
      RawLine = $line
    }) | Out-Null
  }
  # Windows PowerShell 5.1 throws "Argument types do not match" when a
  # generic List[object] is wrapped directly in @(...). Materialize a normal
  # object array before returning it so callers behave consistently on 5.1
  # and PowerShell 7.
  return $cases.ToArray()
}

function Get-RegressionCase {
  param([Parameter(Mandatory = $true)][string]$CaseId)

  if ($CaseId -notmatch '^(PRE|V2|ADM|AUT)-[A-Z0-9-]+$') {
    throw "Invalid regression case ID."
  }
  $matches = @(Get-RegressionCases | Where-Object { $_.CaseId -eq $CaseId })
  if ($matches.Count -ne 1) {
    throw "Regression case must exist exactly once in the matrix: $CaseId"
  }
  return $matches[0]
}

function Read-RegressionDotEnv {
  param([Parameter(Mandatory = $true)][string]$Path)

  $settings = @{}
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    $candidate = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($candidate) -or $candidate.StartsWith('#')) {
      continue
    }
    $separatorIndex = $candidate.IndexOf('=')
    if ($separatorIndex -le 0) {
      continue
    }
    $key = $candidate.Substring(0, $separatorIndex).Trim().TrimStart([char]0xFEFF)
    $value = $candidate.Substring($separatorIndex + 1).Trim()
    if ($value.Length -ge 2) {
      if (
        ($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') -or
        ($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'")
      ) {
        $value = $value.Substring(1, $value.Length - 2)
      }
    }
    $settings[$key] = $value
  }
  return $settings
}

function Get-RegressionSha256Text {
  param([Parameter(Mandatory = $true)][string]$Value)

  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $hash = [System.BitConverter]::ToString($sha.ComputeHash($bytes))
    return $hash.Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Assert-RegressionSandboxProject {
  param(
    [Parameter(Mandatory = $true)][string]$EnvFile,
    [Parameter(Mandatory = $true)][string]$ExpectedProjectRef
  )

  if ($ExpectedProjectRef -notmatch '^[a-z0-9]{8,32}$') {
    throw "Expected sandbox project ref has an invalid format."
  }
  $settings = Read-RegressionDotEnv -Path $EnvFile
  if (-not $settings.ContainsKey('SUPABASE_URL')) {
    throw "SUPABASE_URL is missing."
  }
  $uri = $null
  if (-not [System.Uri]::TryCreate($settings['SUPABASE_URL'], [System.UriKind]::Absolute, [ref]$uri)) {
    throw "SUPABASE_URL is invalid."
  }
  if ($uri.Scheme -ne 'https' -or $uri.Host -notmatch '^([a-z0-9]+)\.supabase\.co$') {
    throw "Only a hosted HTTPS Supabase sandbox endpoint is accepted."
  }
  $actualProjectRef = $Matches[1]
  if (-not $actualProjectRef.Equals($ExpectedProjectRef, [System.StringComparison]::Ordinal)) {
    throw "Supabase endpoint does not match the confirmed sandbox project ref."
  }
  return (Get-RegressionSha256Text -Value $actualProjectRef).Substring(0, 12)
}

function Assert-RegressionDeviceOnline {
  param([Parameter(Mandatory = $true)][string]$DeviceId)

  if ($DeviceId -notmatch '^[A-Za-z0-9._:-]+$') {
    throw "Device ID has an invalid format."
  }
  $output = & adb devices -l 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "adb devices failed."
  }
  $escaped = [regex]::Escape($DeviceId)
  if (-not ($output -match "(?m)^$escaped\s+device(?:\s|$)")) {
    throw "Android device is not online: $DeviceId"
  }
}

function Get-RegressionDeviceMetadata {
  param([Parameter(Mandatory = $true)][string]$DeviceId)

  Assert-RegressionDeviceOnline -DeviceId $DeviceId
  $api = (& adb -s $DeviceId shell getprop ro.build.version.sdk).Trim()
  $model = (& adb -s $DeviceId shell getprop ro.product.model).Trim()
  $size = (& adb -s $DeviceId shell wm size).Trim()
  return [pscustomobject]@{
    DeviceId = $DeviceId
    AndroidApi = $api
    Model = $model
    Resolution = $size
  }
}

function New-RegressionCommandId {
  param(
    [Parameter(Mandatory = $true)][string]$Surface,
    [Parameter(Mandatory = $true)][string]$CaseId
  )

  $timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
  $suffix = Get-Random -Minimum 1000 -Maximum 9999
  return "$timestamp-$Surface-$CaseId-$suffix"
}

function Write-RegressionUtf8File {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )

  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
  }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function ConvertTo-RegressionJsonScalar {
  param([AllowNull()]$Value)
  return ($Value | ConvertTo-Json -Compress)
}

function Get-RegressionGitMetadata {
  Push-Location $script:RegressionRepoRoot
  try {
    $sha = (& git rev-parse --short HEAD).Trim()
    $dirty = [bool](& git status --porcelain)
    return [pscustomobject]@{ Sha = $sha; Dirty = $dirty }
  } finally {
    Pop-Location
  }
}
