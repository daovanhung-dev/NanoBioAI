[CmdletBinding()]
param(
  [ValidateNotNullOrEmpty()]
  [string]$EnvFile = ".env",

  [ValidateRange(5, 120)]
  [int]$TimeoutSec = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

function Resolve-RepoFile {
  param([Parameter(Mandatory = $true)][string]$Path)

  $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
    $Path
  } else {
    Join-Path $repoRoot $Path
  }
  $resolved = [System.IO.Path]::GetFullPath($candidate)
  if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "Environment file was not found: $Path"
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

function Add-ModelCandidate {
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [System.Collections.Generic.List[string]]$Models,
    [AllowNull()][string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return
  }
  foreach ($item in $Value.Split(',')) {
    $model = $item.Trim()
    if ($model.StartsWith("models/")) {
      $model = $model.Substring(7)
    }
    if (-not [string]::IsNullOrWhiteSpace($model) -and -not $Models.Contains($model)) {
      $Models.Add($model) | Out-Null
    }
  }
}

function Get-SafeFailureMessage {
  param([Parameter(Mandatory = $true)]$ErrorRecord)

  $statusCode = $null
  try {
    $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode
  } catch {
    $statusCode = $null
  }

  if ($null -ne $statusCode) {
    return "HTTP $statusCode"
  }
  return $ErrorRecord.Exception.GetType().Name
}

function Get-GeminiText {
  param([Parameter(Mandatory = $true)]$Response)

  $segments = New-Object System.Collections.Generic.List[string]
  $candidatesProperty = $Response.PSObject.Properties["candidates"]
  if ($null -eq $candidatesProperty) {
    return ""
  }

  foreach ($candidate in @($candidatesProperty.Value)) {
    $contentProperty = $candidate.PSObject.Properties["content"]
    if ($null -eq $contentProperty) {
      continue
    }

    $partsProperty = $contentProperty.Value.PSObject.Properties["parts"]
    if ($null -eq $partsProperty) {
      continue
    }

    foreach ($part in @($partsProperty.Value)) {
      $textProperty = $part.PSObject.Properties["text"]
      if ($null -eq $textProperty) {
        continue
      }

      $text = [string]$textProperty.Value
      if (-not [string]::IsNullOrWhiteSpace($text)) {
        $segments.Add($text.Trim()) | Out-Null
      }
    }
  }

  return ($segments -join "`n").Trim()
}

$resolvedEnvFile = Resolve-RepoFile -Path $EnvFile
$settings = Read-DotEnvSettings -Path $resolvedEnvFile

if (-not $settings.ContainsKey("GEMINI_API_KEY") -or [string]::IsNullOrWhiteSpace($settings["GEMINI_API_KEY"])) {
  throw "GEMINI_API_KEY is missing or empty."
}

$baseUrl = if ($settings.ContainsKey("GEMINI_BASE_URL") -and -not [string]::IsNullOrWhiteSpace($settings["GEMINI_BASE_URL"])) {
  $settings["GEMINI_BASE_URL"].Trim().TrimEnd('/')
} else {
  "https://generativelanguage.googleapis.com/v1beta"
}

$models = New-Object System.Collections.Generic.List[string]
foreach ($key in @(
  "GEMINI_CHAT_MODEL",
  "GEMINI_PLAN_MODEL",
  "GEMINI_MODEL",
  "GEMINI_CHAT_FALLBACK_MODELS",
  "GEMINI_PLAN_FALLBACK_MODELS",
  "GEMINI_FALLBACK_MODELS"
)) {
  if ($settings.ContainsKey($key)) {
    Add-ModelCandidate -Models $models -Value $settings[$key]
  }
}
Add-ModelCandidate -Models $models -Value "gemini-3.1-flash-lite,gemini-3.5-flash,gemini-2.5-flash-lite"

$headers = @{
  "x-goog-api-key" = $settings["GEMINI_API_KEY"]
  "Content-Type" = "application/json"
}
$body = @{
  contents = @(
    @{
      role = "user"
      parts = @(@{ text = "Tra ve dung mot tu: OK" })
    }
  )
  generationConfig = @{
    candidateCount = 1
    maxOutputTokens = 512
    temperature = 0
    topP = 0.8
  }
} | ConvertTo-Json -Depth 8 -Compress

$failures = New-Object System.Collections.Generic.List[string]
foreach ($model in $models) {
  $encodedModel = [System.Uri]::EscapeDataString($model)
  $uri = "$baseUrl/models/${encodedModel}:generateContent"
  try {
    $response = Invoke-RestMethod `
      -Uri $uri `
      -Method Post `
      -Headers $headers `
      -Body $body `
      -ContentType "application/json" `
      -TimeoutSec $TimeoutSec

    $text = Get-GeminiText -Response $response
    if ([string]::IsNullOrWhiteSpace($text)) {
      throw "Gemini returned an empty response."
    }

    Write-Host "Gemini connection passed with model: $model"
    return
  } catch {
    $safeFailure = Get-SafeFailureMessage -ErrorRecord $_
    $failures.Add("${model}: $safeFailure") | Out-Null
    Write-Warning "Gemini model check failed for $model ($safeFailure). Trying the next configured model."
  }
}

throw "Gemini connection failed for every configured model. $($failures -join '; ')"
