[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$CampaignRoot,
  [string]$MatrixPath = '',
  [string]$TraceabilityPath = '',
  [switch]$VerifyDeterministic
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

function Add-FullProjectTraceabilityError {
  param([Parameter(Mandatory = $true)][string]$Message)

  $errors.Add($Message) | Out-Null
}

$campaign = Initialize-RegressionCampaign `
  -CampaignRoot $CampaignRoot `
  -MatrixPath $MatrixPath `
  -RequireExisting
$errors = New-Object System.Collections.Generic.List[string]

if ([string]::IsNullOrWhiteSpace($TraceabilityPath)) {
  $TraceabilityPath = '002-traceability-all-bd.json'
}
try {
  $resolvedTraceabilityPath = Resolve-RegressionCampaignFile `
    -Path $TraceabilityPath `
    -Label 'Full-project traceability' `
    -RequireExisting
} catch {
  throw $_.Exception
}

try {
  $report = [System.IO.File]::ReadAllText($resolvedTraceabilityPath, [System.Text.Encoding]::UTF8) |
    ConvertFrom-Json
} catch {
  throw "Full-project traceability JSON is invalid: $($_.Exception.Message)"
}

if ($report.schema_version -ne 1) {
  Add-FullProjectTraceabilityError -Message "Unexpected traceability schema version: $($report.schema_version)"
}
$expectedSources = @('PF', 'AH', 'WR', 'NBI')
$actualSources = @($report.bd_sources | ForEach-Object { $_.id })
if (($actualSources -join ',') -ne ($expectedSources -join ',')) {
  Add-FullProjectTraceabilityError -Message 'Traceability must contain PF, AH, WR, and NBI in canonical order.'
}

$expectedRequirementCounts = @{ PF = 24; AH = 10; WR = 11; NBI = 20 }
foreach ($source in @($report.bd_sources)) {
  if (-not $expectedRequirementCounts.ContainsKey($source.id)) {
    continue
  }
  if ($source.requirements -ne $expectedRequirementCounts[$source.id]) {
    Add-FullProjectTraceabilityError -Message (
      "Unexpected requirement count for $($source.id): $($source.requirements)"
    )
  }
}

$requirements = @($report.requirements)
if ($requirements.Count -ne 65) {
  Add-FullProjectTraceabilityError -Message "Expected 65 four-BD requirements, found $($requirements.Count)."
}
foreach ($requirement in $requirements) {
  if (@('MAPPED', 'GAP') -notcontains $requirement.status) {
    Add-FullProjectTraceabilityError -Message "Invalid requirement status: $($requirement.id)=$($requirement.status)"
  }
  if ($requirement.status -eq 'GAP' -and [string]::IsNullOrWhiteSpace($requirement.gap_reason)) {
    Add-FullProjectTraceabilityError -Message "GAP lacks a documented reason: $($requirement.id)"
  }
  if ($requirement.status -eq 'MAPPED' -and @($requirement.mapped_cases).Count -eq 0) {
    Add-FullProjectTraceabilityError -Message "MAPPED requirement has no exact case: $($requirement.id)"
  }
}

$matrixCases = @(Get-RegressionCases)
if (@($report.matrix_cases).Count -ne $matrixCases.Count) {
  Add-FullProjectTraceabilityError -Message 'Traceability matrix case count does not match the campaign matrix.'
}
foreach ($case in @($report.matrix_cases)) {
  if ([string]::IsNullOrWhiteSpace($case.id)) {
    Add-FullProjectTraceabilityError -Message 'Traceability contains a case without an ID.'
    continue
  }
  $matrixMatch = @($matrixCases | Where-Object { $_.CaseId -eq $case.id })
  if ($matrixMatch.Count -ne 1) {
    Add-FullProjectTraceabilityError -Message "Traceability case is absent or duplicated in matrix: $($case.id)"
  } elseif ($matrixMatch[0].Status -ne $case.status) {
    Add-FullProjectTraceabilityError -Message "Traceability case status mismatch: $($case.id)"
  }
}

if ($VerifyDeterministic) {
  $generator = Join-Path $PSScriptRoot 'New-FullProjectTraceability.ps1'
  $temporarySuffix = [guid]::NewGuid().ToString('N')
  $temporaryMarkdown = Join-Path $campaign.CampaignRoot ".traceability-$temporarySuffix.md"
  $temporaryJson = Join-Path $campaign.CampaignRoot ".traceability-$temporarySuffix.json"
  try {
    & $generator `
      -CampaignRoot $campaign.CampaignRoot `
      -MatrixPath $campaign.MatrixPath `
      -OutputPath $temporaryMarkdown `
      -JsonOutputPath $temporaryJson
    if (-not $?) {
      Add-FullProjectTraceabilityError -Message 'Traceability generator did not complete successfully.'
    } else {
      $expectedJson = [System.IO.File]::ReadAllText($resolvedTraceabilityPath, [System.Text.Encoding]::UTF8)
      $actualJson = [System.IO.File]::ReadAllText($temporaryJson, [System.Text.Encoding]::UTF8)
      if ($expectedJson -ne $actualJson) {
        Add-FullProjectTraceabilityError -Message 'Committed traceability JSON is not deterministic from current sources.'
      }
    }
  } finally {
    foreach ($temporaryPath in @($temporaryMarkdown, $temporaryJson)) {
      if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force
      }
    }
  }
}

if ($errors.Count -gt 0) {
  foreach ($errorMessage in $errors) {
    Write-Error $errorMessage
  }
  throw "Full-project traceability validation failed with $($errors.Count) error(s)."
}
Write-Host 'FULL-PROJECT TRACEABILITY VALIDATION PASSED'
