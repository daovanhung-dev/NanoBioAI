[CmdletBinding()]
param(
  [ValidateNotNullOrEmpty()]
  [string]$DeviceId = "12b304f9",

  [ValidateNotNullOrEmpty()]
  [string]$EnvFile = ".env",

  [ValidateNotNullOrEmpty()]
  [string]$EntryPoint = "lib/main.dart",

  [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$requiredRuntimeKeys = @(
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "AUTH_EMAIL_REDIRECT_URL",
  "GEMINI_API_KEY"
)

function Resolve-RepoFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
    $Path
  } else {
    Join-Path $repoRoot $Path
  }
  $resolved = [System.IO.Path]::GetFullPath($candidate)

  if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "$Label file was not found: $Path"
  }

  return $resolved
}

function Read-DotEnvSettings {
  param([Parameter(Mandatory = $true)][string]$Path)

  $settings = @{}
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    $candidate = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($candidate) -or $candidate.StartsWith("#")) {
      continue
    }

    if ($candidate.StartsWith("export ", [System.StringComparison]::OrdinalIgnoreCase)) {
      $candidate = $candidate.Substring(7).TrimStart()
    }

    $separatorIndex = $candidate.IndexOf("=")
    if ($separatorIndex -le 0) {
      continue
    }

    $key = $candidate.Substring(0, $separatorIndex).Trim().TrimStart([char]0xFEFF)
    $value = $candidate.Substring($separatorIndex + 1).Trim()
    if ($value.Length -ge 2) {
      $firstCharacter = $value[0]
      $lastCharacter = $value[$value.Length - 1]
      if (
        ($firstCharacter -eq '"' -and $lastCharacter -eq '"') -or
        ($firstCharacter -eq "'" -and $lastCharacter -eq "'")
      ) {
        $value = $value.Substring(1, $value.Length - 2).Trim()
      }
    }

    $settings[$key] = $value
  }

  return $settings
}

function Test-IsPlaceholder {
  param([AllowEmptyString()][string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $true
  }

  $normalized = $Value.Trim().ToLowerInvariant()
  $placeholderPatterns = @(
    '^<[^>]+>$',
    '^\$\{[^}]+\}$',
    '^(your|replace|change)[-_ ]',
    '^changeme$',
    'placeholder',
    'your-project',
    'your-supabase',
    'example\.(com|org|net)'
  )

  foreach ($pattern in $placeholderPatterns) {
    if ($normalized -match $pattern) {
      return $true
    }
  }

  return $false
}

function Assert-RuntimeEnvironment {
  param([Parameter(Mandatory = $true)][string]$Path)

  $settings = Read-DotEnvSettings -Path $Path
  $invalidKeys = New-Object System.Collections.Generic.List[string]

  foreach ($key in $requiredRuntimeKeys) {
    if (-not $settings.ContainsKey($key) -or (Test-IsPlaceholder -Value $settings[$key])) {
      $invalidKeys.Add($key) | Out-Null
    }
  }

  if ($invalidKeys.Count -gt 0) {
    throw "Environment validation failed. Set non-empty, non-placeholder values for: $($invalidKeys -join ', ')."
  }
}

function Get-DartDefineArguments {
  param([Parameter(Mandatory = $true)][hashtable]$Settings)

  $keys = @(
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "AUTH_EMAIL_REDIRECT_URL",
    "AUTH_CONFIRM_EMAIL_REQUIRED",
    "GEMINI_API_KEY",
    "GEMINI_BASE_URL",
    "GEMINI_MODEL",
    "GEMINI_FALLBACK_MODELS",
    "GEMINI_PLAN_MODEL",
    "GEMINI_PLAN_FALLBACK_MODELS",
    "GEMINI_PLAN_OVERFLOW_MODELS",
    "GEMINI_CHAT_MODEL",
    "GEMINI_CHAT_FALLBACK_MODELS",
    "ONBOARDING_AI_DEV_CHECK_ENABLED"
  )
  $arguments = New-Object System.Collections.Generic.List[string]

  foreach ($key in $keys) {
    if ($Settings.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace($Settings[$key])) {
      $arguments.Add("--dart-define=$key=$($Settings[$key])") | Out-Null
    }
  }

  return $arguments.ToArray()
}

function Invoke-FlutterRun {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)

  # gradlew.bat enables command echo when DEBUG exists. Flutter forwards Dart
  # defines to Gradle, so remove DEBUG while the child process runs to prevent
  # encoded configuration values from being echoed to the terminal.
  $debugWasDefined = Test-Path Env:DEBUG
  $previousDebugValue = if ($debugWasDefined) { $env:DEBUG } else { $null }
  $exitCode = $null

  try {
    Remove-Item Env:DEBUG -ErrorAction SilentlyContinue
    & flutter @Arguments
    $exitCode = $LASTEXITCODE
  }
  finally {
    if ($debugWasDefined) {
      Set-Item Env:DEBUG -Value $previousDebugValue
    } else {
      Remove-Item Env:DEBUG -ErrorAction SilentlyContinue
    }
  }

  if ($null -eq $exitCode) {
    throw "flutter run did not return an exit code."
  }
  if ($exitCode -ne 0) {
    throw "flutter run failed with exit code $exitCode."
  }
}

$resolvedEnvFile = Resolve-RepoFile -Path $EnvFile -Label "Environment"
$resolvedEntryPoint = Resolve-RepoFile -Path $EntryPoint -Label "Entry point"
$environment = Read-DotEnvSettings -Path $resolvedEnvFile
Assert-RuntimeEnvironment -Path $resolvedEnvFile

Write-Host "Authentication and AI environment validation passed."
if ($ValidateOnly) {
  Write-Host "Validation-only mode completed; Flutter was not started."
  return
}

$flutterArguments = @(
  "run",
  "-d",
  $DeviceId,
  "-t",
  $resolvedEntryPoint
) + (Get-DartDefineArguments -Settings $environment)

Write-Host "Starting Flutter on device $DeviceId with validated local configuration."
Push-Location $repoRoot
try {
  Invoke-FlutterRun -Arguments $flutterArguments
}
finally {
  Pop-Location
}
