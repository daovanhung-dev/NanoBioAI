[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$CaseId,
  [Parameter(Mandatory = $true)]
  [ValidateSet('PENDING', 'PASS', 'FAIL', 'BLOCKED', 'N/A')]
  [string]$Status,
  [ValidateSet('preflight', 'v2', 'admin', 'automation')]
  [string]$Surface = 'preflight',
  [ValidateSet('e2e', 'integration', 'contract', 'report')]
  [string]$CaseType = 'e2e',
  [string[]]$Coverage = @(),
  [string[]]$Personas = @(),
  [string[]]$DdRefs = @(),
  [string]$RouteOrSurface = '',
  [string]$EntryPoint = '',
  [string]$RunId = '',
  [string]$CommandId = '',
  [string]$DeviceId = '',
  [string[]]$Steps = @(),
  [string]$ActualResult = '',
  [string[]]$Artifacts = @(),
  [string]$DefectId = '',
  [string]$FixRef = '',
  [string[]]$RegressionTests = @(),
  [string]$RetestRunId = '',
  [ValidateSet('', 'YES')][string]$RedactionConfirmed = '',
  [switch]$UpdateMatrix,
  [switch]$Force
)

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

$case = Get-RegressionCase -CaseId $CaseId
$notePath = Assert-RegressionPathInsideRoot `
  -Path (Join-Path $script:RegressionEvidenceRoot "evidence/$CaseId.md") `
  -Root $script:RegressionEvidenceRoot
if ((Test-Path -LiteralPath $notePath -PathType Leaf) -and -not $Force) {
  throw 'Evidence note already exists; use -Force only for an explicit update.'
}

if ($Personas.Count -eq 0 -and -not [string]::IsNullOrWhiteSpace($case.Persona)) {
  $Personas = @($case.Persona -replace '`', '')
}
if ($Steps.Count -eq 0) { $Steps = @('Chưa thực thi.') }
if ([string]::IsNullOrWhiteSpace($ActualResult)) {
  $ActualResult = if ($Status -eq 'PENDING') { 'Chưa thực thi.' } else { '' }
}

if ($Status -in @('PASS', 'FAIL', 'BLOCKED')) {
  if ([string]::IsNullOrWhiteSpace($ActualResult)) {
    throw "$Status requires an actual result or blocker reason."
  }
  if ([string]::IsNullOrWhiteSpace($CommandId)) {
    throw "$Status requires a command ID."
  }
}
if ($Status -eq 'PASS') {
  if ($RedactionConfirmed -ne 'YES') {
    throw 'PASS requires explicit redaction confirmation.'
  }
  if ($CaseId -notlike 'PRE-*' -and $DdRefs.Count -eq 0) {
    throw 'Business PASS requires at least one DD reference.'
  }
  $canonicalAsset = Join-Path $script:RegressionEvidenceRoot "assets/$CaseId-pass.png"
  if (-not (Test-Path -LiteralPath $canonicalAsset -PathType Leaf)) {
    throw 'PASS requires the canonical main PNG.'
  }
  if ($Artifacts -notcontains "assets/$CaseId-pass.png") {
    $Artifacts = @("assets/$CaseId-pass.png") + $Artifacts
  }
}

$device = if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  [pscustomobject]@{ DeviceId = ''; AndroidApi = ''; Model = ''; Resolution = '' }
} else {
  Get-RegressionDeviceMetadata -DeviceId $DeviceId
}
$git = Get-RegressionGitMetadata
$artifactYaml = New-Object System.Collections.Generic.List[string]
foreach ($artifact in $Artifacts) {
  $artifactPath = Assert-RegressionPathInsideRoot `
    -Path (Join-Path $script:RegressionEvidenceRoot $artifact) `
    -Root $script:RegressionEvidenceRoot
  if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
    throw "Artifact does not exist: $artifact"
  }
  $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash.ToLowerInvariant()
  $kind = if ($artifact -eq "assets/$CaseId-pass.png") { 'pass_main' } `
    elseif ($artifact -match 'fail-before-fix') { 'fail_before' } `
    else { 'supporting' }
  $artifactYaml.Add("  - path: $(ConvertTo-RegressionJsonScalar $artifact)") | Out-Null
  $artifactYaml.Add("    kind: $kind") | Out-Null
  $artifactYaml.Add("    sha256: $sha") | Out-Null
  $artifactYaml.Add('    redacted: true') | Out-Null
}
if ($artifactYaml.Count -eq 0) { $artifactYaml.Add('  []') | Out-Null }

$yamlArray = {
  param([string[]]$Values)
  if ($Values.Count -eq 0) { return '[]' }
  return '[' + (($Values | ForEach-Object { ConvertTo-RegressionJsonScalar $_ }) -join ', ') + ']'
}
$startedAt = (Get-Date).ToUniversalTime().ToString('o')
$bodySteps = ($Steps | ForEach-Object { "1. $_" }) -join "`n"
$module = if ($CaseId -like 'PRE-*') {
  'PRE'
} else {
  ($CaseId -split '-')[1]
}
$content = @"
---
case_id: $CaseId
status: $Status
surface: $Surface
module: $(ConvertTo-RegressionJsonScalar $module)
case_type: $CaseType
coverage: $(& $yamlArray $Coverage)
personas: $(& $yamlArray $Personas)
bd_refs: [$(ConvertTo-RegressionJsonScalar $case.BdRefs)]
dd_refs: $(& $yamlArray $DdRefs)
route_or_surface: $(ConvertTo-RegressionJsonScalar $RouteOrSurface)
entrypoint: $(ConvertTo-RegressionJsonScalar $EntryPoint)
run_id: $(ConvertTo-RegressionJsonScalar $RunId)
command_id: $(ConvertTo-RegressionJsonScalar $CommandId)
device:
  alias: $(ConvertTo-RegressionJsonScalar $device.DeviceId)
  android_api: $(ConvertTo-RegressionJsonScalar $device.AndroidApi)
  model: $(ConvertTo-RegressionJsonScalar $device.Model)
  resolution: $(ConvertTo-RegressionJsonScalar $device.Resolution)
build:
  git_sha: $(ConvertTo-RegressionJsonScalar $git.Sha)
  dirty: $($git.Dirty.ToString().ToLowerInvariant())
  package: $script:RegressionPackageName
started_at: $startedAt
finished_at: $startedAt
artifacts:
$($artifactYaml -join "`n")
defect_id: $(ConvertTo-RegressionJsonScalar $DefectId)
fix_ref: $(ConvertTo-RegressionJsonScalar $FixRef)
regression_tests: $(& $yamlArray $RegressionTests)
retest_run_id: $(ConvertTo-RegressionJsonScalar $RetestRunId)
---

# $CaseId

## Persona / tiền điều kiện

$($Personas -join ', ')

## Bước thực hiện

$bodySteps

## Kết quả mong đợi

$($case.Scenario)

## Kết quả thực tế

$ActualResult

## Lỗi / fix / regression retest

- Defect: $DefectId
- Fix: $FixRef
- Retest run: $RetestRunId

## Ghi chú bảo mật

- Dữ liệu synthetic; artifact đã được xác nhận che dữ liệu: $RedactionConfirmed.
- Không lưu credential, raw AI payload, PII hoặc dữ liệu sức khỏe nhạy cảm.
"@
Write-RegressionUtf8File -Path $notePath -Content $content

if ($UpdateMatrix) {
  $lines = [System.IO.File]::ReadAllLines($script:RegressionMatrixPath)
  $updated = 0
  for ($index = 0; $index -lt $lines.Length; $index++) {
    if ($lines[$index] -match "^\|\s*$([regex]::Escape($CaseId))\s*\|") {
      $lines[$index] = $lines[$index] -replace `
        '\|\s*(PENDING|PASS|FAIL|BLOCKED|N/A)\s*\|\s*$', `
        "| $Status |"
      $updated++
    }
  }
  if ($updated -ne 1) { throw 'Matrix status update was not unique.' }
  Write-RegressionUtf8File `
    -Path $script:RegressionMatrixPath `
    -Content (($lines -join "`r`n") + "`r`n")
}

Write-Host "Evidence note written: evidence/$CaseId.md"
