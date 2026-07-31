[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$CampaignRoot,
  [string]$MatrixPath = '',
  [string]$OutputPath = '',
  [string]$JsonOutputPath = '',
  [switch]$NoWrite,
  [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

function Read-FullProjectUtf8Text {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Required source file was not found: $Path"
  }
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-FullProjectRepoRelativePath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$RepoRoot
  )

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $fullRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  )
  $prefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
  if (-not $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Path is outside the repository root: $fullPath"
  }
  return $fullPath.Substring($prefix.Length).Replace(
    [System.IO.Path]::DirectorySeparatorChar,
    [char]'/'
  )
}

function Resolve-FullProjectOutputPath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$CampaignRoot
  )

  $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
    $Path
  } else {
    Join-Path $CampaignRoot $Path
  }
  return Assert-RegressionPathInsideRoot -Path $candidate -Root $CampaignRoot
}

function Get-FullProjectRequirementIds {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Pattern
  )

  $ids = New-Object 'System.Collections.Generic.List[string]'
  foreach ($match in [regex]::Matches($Text, $Pattern)) {
    $value = $match.Value
    if (-not $ids.Contains($value)) {
      $ids.Add($value)
    }
  }
  return $ids.ToArray()
}

function Test-FullProjectRequirementReference {
  param(
    [Parameter(Mandatory = $true)]$Case,
    [Parameter(Mandatory = $true)][string]$SourceId,
    [Parameter(Mandatory = $true)][string]$RawId
  )

  $references = "$($Case.BdRefs) $($Case.Scenario)"
  $casePrefix = ($Case.CaseId -split '-')[0]
  $hasRawId = [regex]::IsMatch(
    $references,
    ('(?<![A-Z0-9]){0}(?![A-Z0-9])' -f [regex]::Escape($RawId)),
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )

  switch ($SourceId) {
    'PF' {
      if (-not $hasRawId) { return $false }
      return $casePrefix -in @('PRE', 'V2', 'ADM', 'ADMIN', 'AUT', 'PF') -or
        $references -match '(?i)(?:\bPF\b|Product\s*Flow|M(?:0[1-9]|1[0-9])\b)'
    }
    'AH' {
      if ($Case.CaseId -match (('-{0}(?:-|$)' -f [regex]::Escape($RawId)))) {
        return $true
      }
      return $hasRawId -and (
        $casePrefix -eq 'AH' -or
        $references -match '(?i)(?:\bAH\b|Advanced\s*Health|M2[0-9]\b)'
      )
    }
    'WR' {
      return $hasRawId
    }
    'NBI' {
      return $hasRawId
    }
    default {
      throw "Unsupported BD source ID: $SourceId"
    }
  }
}

function Get-FullProjectRequirementStatus {
  param([Parameter(Mandatory = $true)][object[]]$Cases)

  if ($Cases.Count -eq 0) {
    return 'GAP'
  }
  return 'MAPPED'
}

$campaign = Initialize-RegressionCampaign `
  -CampaignRoot $CampaignRoot `
  -MatrixPath $MatrixPath `
  -RequireExisting
$repoRoot = $script:RegressionRepoRoot
$cases = @(Get-RegressionCases | Sort-Object CaseId)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = '002-traceability-all-bd.md'
}
if ([string]::IsNullOrWhiteSpace($JsonOutputPath)) {
  $JsonOutputPath = '002-traceability-all-bd.json'
}
$OutputPath = Resolve-FullProjectOutputPath -Path $OutputPath -CampaignRoot $campaign.CampaignRoot
$JsonOutputPath = Resolve-FullProjectOutputPath -Path $JsonOutputPath -CampaignRoot $campaign.CampaignRoot

$sources = @(
  [pscustomobject][ordered]@{
    id = 'PF'
    title = 'Product Flow Sale Admin v2.0'
    path = Join-Path $repoRoot 'docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md'
    document_status = 'Approved'
    expected_requirement_count = 24
    pattern = '(?<![A-Z0-9-])AC-\d{2}(?![0-9])'
  },
  [pscustomobject][ordered]@{
    id = 'AH'
    title = 'Advanced Health Features v1.0'
    path = Join-Path $repoRoot 'docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md'
    document_status = 'Draft - UI catalog shell approved'
    expected_requirement_count = 10
    pattern = ''
  },
  [pscustomobject][ordered]@{
    id = 'WR'
    title = 'Daily Proof Wellness Rewards v1.0'
    path = Join-Path $repoRoot 'docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md'
    document_status = 'Approved'
    expected_requirement_count = 11
    pattern = '(?<![A-Z0-9-])WR-AC-\d{3}(?![0-9])'
  },
  [pscustomobject][ordered]@{
    id = 'NBI'
    title = 'Nabi notification and bridge'
    path = Join-Path $repoRoot 'docs/BD/notification_Nabi/BD_thong_bao_nut_noi_Nabi.md'
    document_status = 'Approved with terminology gap tracked by campaign'
    expected_requirement_count = 20
    pattern = '(?<![A-Z0-9-])NBI-(?:FREE|ANNUAL|STREAK|REWARD|REPORT|REFERRAL|CARE|PROFILE)-\d{3}(?![0-9])'
  }
)

$requirements = New-Object 'System.Collections.Generic.List[object]'
foreach ($source in $sources) {
  $text = Read-FullProjectUtf8Text -Path $source.path
  $rawIds = if ($source.id -eq 'AH') {
    @(20..29 | ForEach-Object { 'M{0:D2}' -f $_ })
  } else {
    @(Get-FullProjectRequirementIds -Text $text -Pattern $source.pattern)
  }
  if ($rawIds.Count -ne $source.expected_requirement_count) {
    throw "Unexpected requirement inventory for $($source.id): expected $($source.expected_requirement_count), found $($rawIds.Count)."
  }

  foreach ($rawId in $rawIds) {
    $mappedCases = @(
      $cases | Where-Object {
        Test-FullProjectRequirementReference -Case $_ -SourceId $source.id -RawId $rawId
      } | ForEach-Object { $_.CaseId } | Sort-Object -Unique
    )
    $mappedCaseObjects = @($cases | Where-Object { $mappedCases -contains $_.CaseId })
    $status = Get-FullProjectRequirementStatus -Cases $mappedCaseObjects
    $requirements.Add([pscustomobject][ordered]@{
        id = "$($source.id):$rawId"
        source_id = $source.id
        raw_id = $rawId
        document_status = $source.document_status
        status = $status
        mapped_cases = @($mappedCases)
        execution_statuses = @($mappedCaseObjects | ForEach-Object { $_.Status } | Sort-Object -Unique)
        gap_reason = if ($status -eq 'GAP') { 'No exact campaign matrix reference.' } else { '' }
      }) | Out-Null
  }
}

$requirements = $requirements.ToArray()
$caseRequirementMap = @{}
foreach ($case in $cases) {
  $caseRequirementMap[$case.CaseId] = @(
    $requirements |
      Where-Object { $_.mapped_cases -contains $case.CaseId } |
      ForEach-Object { $_.id } |
      Sort-Object
  )
}

$sourceResults = @(
  foreach ($source in $sources) {
    $sourceRequirements = @($requirements | Where-Object { $_.source_id -eq $source.id })
    [pscustomobject][ordered]@{
      id = $source.id
      title = $source.title
      source = Get-FullProjectRepoRelativePath -Path $source.path -RepoRoot $repoRoot
      document_status = $source.document_status
      requirements = $sourceRequirements.Count
      mapped = @($sourceRequirements | Where-Object { $_.status -eq 'MAPPED' }).Count
      gaps = @($sourceRequirements | Where-Object { $_.status -eq 'GAP' }).Count
    }
  }
)

$report = [pscustomobject][ordered]@{
  schema_version = 1
  generated_by = 'tools/regression/New-FullProjectTraceability.ps1'
  campaign = [pscustomobject][ordered]@{
    root = Get-FullProjectRepoRelativePath -Path $campaign.CampaignRoot -RepoRoot $repoRoot
    matrix = Get-FullProjectRepoRelativePath -Path $campaign.MatrixPath -RepoRoot $repoRoot
  }
  bd_sources = @($sourceResults)
  summary = [pscustomobject][ordered]@{
    cases = $cases.Count
    requirements = $requirements.Count
    mapped = @($requirements | Where-Object { $_.status -eq 'MAPPED' }).Count
    gaps = @($requirements | Where-Object { $_.status -eq 'GAP' }).Count
  }
  requirements = @($requirements)
  matrix_cases = @(
    $cases | ForEach-Object {
      [pscustomobject][ordered]@{
        id = $_.CaseId
        status = $_.Status
        bd_refs = $_.BdRefs
        mapped_requirements = @($caseRequirementMap[$_.CaseId])
      }
    }
  )
}

$markdown = New-Object 'System.Collections.Generic.List[string]'
$markdown.Add('<!-- Generated by tools/regression/New-FullProjectTraceability.ps1. Do not edit manually. -->')
$markdown.Add('')
$markdown.Add('# Full-project traceability - four BD sources')
$markdown.Add('')
$markdown.Add('`MAPPED` means that a case cites the exact source-specific requirement. It is coverage, not an execution PASS. `GAP` records a missing exact citation and is not silently converted to a runtime failure.')
$markdown.Add('')
$markdown.Add('## BD source summary')
$markdown.Add('')
$markdown.Add('| Source | Document status | Requirements | Mapped | Gap |')
$markdown.Add('|---|---|---:|---:|---:|')
foreach ($source in $sourceResults) {
  $markdown.Add(('| {0} | {1} | {2} | {3} | {4} |' -f $source.id, $source.document_status, $source.requirements, $source.mapped, $source.gaps))
}
$markdown.Add('')
$markdown.Add('## Exact requirement mapping')
$markdown.Add('')
$markdown.Add('| Requirement | Document state | Coverage | Cases | Execution states | Gap reason |')
$markdown.Add('|---|---|---|---|---|---|')
foreach ($requirement in $requirements) {
  $mappedCases = if ($requirement.mapped_cases.Count -gt 0) { $requirement.mapped_cases -join ', ' } else { '-' }
  $executionStates = if ($requirement.execution_statuses.Count -gt 0) { $requirement.execution_statuses -join ', ' } else { '-' }
  $gapReason = if ([string]::IsNullOrWhiteSpace($requirement.gap_reason)) { '-' } else { $requirement.gap_reason }
  $markdown.Add(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f
      $requirement.id,
      $requirement.document_status,
      $requirement.status,
      $mappedCases,
      $executionStates,
      $gapReason))
}
$markdown.Add('')
$markdown.Add('The machine-readable companion is `002-traceability-all-bd.json`.')
$markdown.Add('')

$markdownText = ($markdown -join "`n") + "`n"
$jsonText = (($report | ConvertTo-Json -Depth 12).Replace("`r`n", "`n")) + "`n"
if (-not $NoWrite) {
  Write-RegressionUtf8File -Path $OutputPath -Content $markdownText
  Write-RegressionUtf8File -Path $JsonOutputPath -Content $jsonText
}

Write-Host (
  'Full-project traceability {0}: sources={1}, requirements={2}, cases={3}.' -f
  $(if ($NoWrite) { 'validated without writing' } else { 'generated' }),
  $sourceResults.Count,
  $requirements.Count,
  $cases.Count
)
if ($PassThru) {
  Write-Output $report
}
