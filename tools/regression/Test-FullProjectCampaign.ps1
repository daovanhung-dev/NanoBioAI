[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$CampaignRoot,
  [string]$MatrixPath = '',
  [switch]$RequireTraceability,
  [string]$TraceabilityPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

$campaign = Initialize-RegressionCampaign `
  -CampaignRoot $CampaignRoot `
  -MatrixPath $MatrixPath `
  -RequireExisting
$cases = @(Get-RegressionCases)
$errors = New-Object System.Collections.Generic.List[string]
$allowedStatuses = @('PASS', 'FAIL', 'BLOCKED', 'N/A', 'GAP')

function Add-CampaignValidationError {
  param([Parameter(Mandatory = $true)][string]$Message)

  $errors.Add($Message) | Out-Null
}

function Get-CampaignFrontMatterValue {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Name
  )

  $match = [regex]::Match(
    $Text,
    ('(?m)^{0}:\s*(?<value>.*?)\s*$' -f [regex]::Escape($Name))
  )
  if (-not $match.Success) {
    return ''
  }

  $value = $match.Groups['value'].Value.Trim()
  if ($value -eq '""' -or $value -eq "''" -or $value -eq 'null') {
    return ''
  }
  if ($value.Length -ge 2 -and (
      ($value.StartsWith('"') -and $value.EndsWith('"')) -or
      ($value.StartsWith("'") -and $value.EndsWith("'"))
    )) {
    $value = $value.Substring(1, $value.Length - 2)
  }
  return $value.Trim()
}

function Get-CampaignEvidenceArtifactPaths {
  param([Parameter(Mandatory = $true)][string]$Text)

  $paths = New-Object 'System.Collections.Generic.List[string]'
  foreach ($match in [regex]::Matches($Text, '(?m)^\s*-\s*path:\s*(?<value>.+?)\s*$')) {
    $value = $match.Groups['value'].Value.Trim().Trim('"', "'", '`')
    if (-not [string]::IsNullOrWhiteSpace($value) -and -not $paths.Contains($value)) {
      $paths.Add($value)
    }
  }
  foreach ($match in [regex]::Matches($Text, '(?<![A-Za-z0-9_./-])(?<value>assets/[A-Za-z0-9._/-]+)')) {
    $value = $match.Groups['value'].Value
    if (-not $paths.Contains($value)) {
      $paths.Add($value)
    }
  }
  return $paths.ToArray()
}

function Test-CampaignArtifactReference {
  param(
    [Parameter(Mandatory = $true)][string]$Artifact,
    [Parameter(Mandatory = $true)][string]$CaseId
  )

  try {
    $artifactPath = Resolve-RegressionCampaignFile `
      -Path $Artifact `
      -Label "Artifact for $CaseId" `
      -RequireExisting
  } catch {
    Add-CampaignValidationError -Message $_.Exception.Message
    return
  }

  if ($Artifact -match '(?i)\.png$' -and -not (Test-RegressionPngFile -Path $artifactPath)) {
    Add-CampaignValidationError -Message "Artifact is not a valid PNG for ${CaseId}: $Artifact"
  }
}

if ($cases.Count -eq 0) {
  Add-CampaignValidationError -Message 'Campaign matrix contains no supported case rows.'
}

$duplicates = @($cases | Group-Object CaseId | Where-Object { $_.Count -ne 1 })
foreach ($duplicate in $duplicates) {
  Add-CampaignValidationError -Message "Duplicate campaign case ID: $($duplicate.Name)"
}

$matrixText = [System.IO.File]::ReadAllText($script:RegressionMatrixPath)
if ($matrixText -match 'lib/main_v2\.dart|lib/main_admin\.dart') {
  Add-CampaignValidationError -Message 'Campaign matrix must use the unified lib/main.dart entrypoint.'
}

foreach ($case in $cases) {
  if ($allowedStatuses -notcontains $case.Status) {
    Add-CampaignValidationError -Message "Campaign status is not final for $($case.CaseId): $($case.Status)"
  }
  if ($case.Status -eq 'PENDING') {
    Add-CampaignValidationError -Message "Campaign has a PENDING case: $($case.CaseId)"
  }
  if ([string]::IsNullOrWhiteSpace($case.EvidencePath)) {
    Add-CampaignValidationError -Message "Evidence path is missing from the matrix: $($case.CaseId)"
    continue
  }

  try {
    $evidencePath = Resolve-RegressionCampaignFile `
      -Path $case.EvidencePath `
      -Label "Evidence for $($case.CaseId)" `
      -RequireExisting
  } catch {
    Add-CampaignValidationError -Message $_.Exception.Message
    continue
  }

  $note = [System.IO.File]::ReadAllText($evidencePath)
  if ($note -match 'lib/main_v2\.dart|lib/main_admin\.dart') {
    Add-CampaignValidationError -Message "Evidence uses a retired entrypoint: $($case.CaseId)"
  }
  $noteCaseId = Get-CampaignFrontMatterValue -Text $note -Name 'case_id'
  if ($noteCaseId -ne $case.CaseId) {
    Add-CampaignValidationError -Message "Evidence case_id mismatch: $($case.CaseId)"
  }
  $noteStatus = Get-CampaignFrontMatterValue -Text $note -Name 'status'
  if ($noteStatus -ne $case.Status) {
    Add-CampaignValidationError -Message "Evidence status mismatch: $($case.CaseId)"
  }

  $actualResult = Get-CampaignFrontMatterValue -Text $note -Name 'actual_result'
  $commandId = Get-CampaignFrontMatterValue -Text $note -Name 'command_id'
  $rationale = Get-CampaignFrontMatterValue -Text $note -Name 'rationale'
  $technicalEvidence = Get-CampaignFrontMatterValue -Text $note -Name 'technical_evidence'
  $entryPoint = Get-CampaignFrontMatterValue -Text $note -Name 'entrypoint'
  $artifacts = @(Get-CampaignEvidenceArtifactPaths -Text $note)

  if (-not [string]::IsNullOrWhiteSpace($entryPoint) -and $entryPoint -ne 'lib/main.dart') {
    Add-CampaignValidationError -Message "Evidence entrypoint is not lib/main.dart: $($case.CaseId)"
  }

  foreach ($artifact in $artifacts) {
    Test-CampaignArtifactReference -Artifact $artifact -CaseId $case.CaseId
  }
  $hasPngArtifact = @($artifacts | Where-Object { $_ -match '(?i)\.png$' }).Count -gt 0
  if ($hasPngArtifact -and $note -notmatch '(?m)^\s+redacted:\s*true\s*$') {
    Add-CampaignValidationError -Message "PNG artifact lacks redaction confirmation: $($case.CaseId)"
  }

  if ($case.Status -in @('PASS', 'FAIL', 'BLOCKED')) {
    if ([string]::IsNullOrWhiteSpace($actualResult)) {
      Add-CampaignValidationError -Message "$($case.Status) lacks actual_result: $($case.CaseId)"
    }
    if ([string]::IsNullOrWhiteSpace($commandId)) {
      Add-CampaignValidationError -Message "$($case.Status) lacks command_id: $($case.CaseId)"
    }
  }

  if ($case.Status -eq 'PASS') {
    if ([string]::IsNullOrWhiteSpace($case.AssetPath)) {
      Add-CampaignValidationError -Message "PASS lacks the main screenshot path in the matrix: $($case.CaseId)"
    } else {
      try {
        $mainAsset = Resolve-RegressionCampaignFile `
          -Path $case.AssetPath `
          -Label "PASS main PNG for $($case.CaseId)" `
          -RequireExisting
        if (-not (Test-RegressionPngFile -Path $mainAsset)) {
          Add-CampaignValidationError -Message "PASS main artifact is not a valid PNG: $($case.CaseId)"
        }
      } catch {
        Add-CampaignValidationError -Message $_.Exception.Message
      }
    }
    if ($note -notmatch '(?m)^\s+redacted:\s*true\s*$') {
      Add-CampaignValidationError -Message "PASS lacks artifact redaction confirmation: $($case.CaseId)"
    }
    if ($artifacts -notcontains $case.AssetPath) {
      Add-CampaignValidationError -Message "PASS evidence does not cite the main matrix asset: $($case.CaseId)"
    }
  }

  if ($case.Status -in @('FAIL', 'BLOCKED')) {
    if ($artifacts.Count -eq 0 -and [string]::IsNullOrWhiteSpace($technicalEvidence)) {
      Add-CampaignValidationError -Message "$($case.Status) lacks artifact or technical evidence: $($case.CaseId)"
    }
  }

  if ($case.Status -in @('N/A', 'GAP')) {
    if ([string]::IsNullOrWhiteSpace($rationale) -and [string]::IsNullOrWhiteSpace($actualResult)) {
      Add-CampaignValidationError -Message "$($case.Status) lacks a rationale: $($case.CaseId)"
    }
  }
}

if ($RequireTraceability) {
  $traceabilityValidator = Join-Path $PSScriptRoot 'Test-FullProjectTraceability.ps1'
  if (-not (Test-Path -LiteralPath $traceabilityValidator -PathType Leaf)) {
    Add-CampaignValidationError -Message 'Campaign traceability validator was not found.'
  } else {
    $traceabilityArguments = @{
      CampaignRoot = $campaign.CampaignRoot
      MatrixPath = $campaign.MatrixPath
    }
    if (-not [string]::IsNullOrWhiteSpace($TraceabilityPath)) {
      $traceabilityArguments.TraceabilityPath = $TraceabilityPath
    }
    try {
      & $traceabilityValidator @traceabilityArguments
      if (-not $?) {
        Add-CampaignValidationError -Message 'Campaign traceability validation did not complete successfully.'
      }
    } catch {
      Add-CampaignValidationError -Message "Campaign traceability validation failed: $($_.Exception.Message)"
    }
  }
}

$statusSummary = $cases | Group-Object Status | Sort-Object Name
Write-Host "Campaign cases: $($cases.Count)"
foreach ($group in $statusSummary) {
  Write-Host "  $($group.Name): $($group.Count)"
}
if ($errors.Count -gt 0) {
  foreach ($errorMessage in $errors) {
    Write-Error $errorMessage
  }
  throw "Full-project campaign validation failed with $($errors.Count) error(s)."
}
Write-Host 'FULL-PROJECT CAMPAIGN VALIDATION PASSED'
