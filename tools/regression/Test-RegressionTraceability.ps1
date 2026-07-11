[CmdletBinding()]
param(
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Equal {
  param(
    [Parameter(Mandatory = $true)]$Actual,
    [Parameter(Mandatory = $true)]$Expected,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if ($Actual -ne $Expected) {
    throw "$Label mismatch. Expected '$Expected', found '$Actual'."
  }
}

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot '../..'
}
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

$generatorPath = Join-Path $RepoRoot 'tools/regression/New-RegressionTraceability.ps1'
$committedMarkdownPath = Join-Path $RepoRoot 'docs/test/v2-admin-regression/002-traceability-bd-dd-cases.md'
$committedJsonPath = Join-Path $RepoRoot 'docs/test/v2-admin-regression/002-traceability-bd-dd-cases.json'

foreach ($requiredPath in @($generatorPath, $committedMarkdownPath, $committedJsonPath)) {
  if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
    throw "Required traceability file was not found: $requiredPath"
  }
}

$temporaryMarkdown = [System.IO.Path]::GetTempFileName()
$temporaryJson = [System.IO.Path]::GetTempFileName()

try {
  & $generatorPath `
    -RepoRoot $RepoRoot `
    -OutputPath $temporaryMarkdown `
    -JsonOutputPath $temporaryJson

  $encoding = [System.Text.Encoding]::UTF8
  $expectedMarkdown = [System.IO.File]::ReadAllText($committedMarkdownPath, $encoding)
  $actualMarkdown = [System.IO.File]::ReadAllText($temporaryMarkdown, $encoding)
  $expectedJson = [System.IO.File]::ReadAllText($committedJsonPath, $encoding)
  $actualJson = [System.IO.File]::ReadAllText($temporaryJson, $encoding)

  Assert-Equal -Actual $actualMarkdown -Expected $expectedMarkdown -Label 'Generated Markdown'
  Assert-Equal -Actual $actualJson -Expected $expectedJson -Label 'Generated JSON'

  $report = $expectedJson | ConvertFrom-Json
  Assert-Equal -Actual $report.schema_version -Expected 1 -Label 'Schema version'
  Assert-Equal -Actual @($report.modules).Count -Expected 19 -Label 'Module count'
  Assert-Equal -Actual @($report.bd_acceptance).Count -Expected 24 -Label 'BD AC count'
  Assert-Equal -Actual @($report.dd_acceptance).Count -Expected 494 -Label 'DD acceptance count'
  Assert-Equal -Actual @($report.overall_tests).Count -Expected 38 -Label 'Overall TC count'

  Assert-Equal -Actual @(
    $report.dd_acceptance | Where-Object { $_.kind -eq 'feature' }
  ).Count -Expected 152 -Label 'Feature acceptance count'
  Assert-Equal -Actual @(
    $report.dd_acceptance | Where-Object { $_.kind -eq 'function' }
  ).Count -Expected 190 -Label 'Function acceptance count'
  Assert-Equal -Actual @(
    $report.dd_acceptance | Where-Object { $_.kind -eq 'view' }
  ).Count -Expected 152 -Label 'View acceptance count'

  $expectedModuleIds = @(1..19 | ForEach-Object { 'M{0:D2}' -f $_ })
  $actualModuleIds = @($report.modules | ForEach-Object { $_.id })
  Assert-Equal `
    -Actual ($actualModuleIds -join ',') `
    -Expected ($expectedModuleIds -join ',') `
    -Label 'Module sequence'

  $allDdIds = @(
    $report.dd_acceptance | ForEach-Object { $_.id }
    $report.overall_tests | ForEach-Object { $_.id }
  )
  Assert-Equal `
    -Actual @($allDdIds | Sort-Object -Unique).Count `
    -Expected $allDdIds.Count `
    -Label 'Unique DD/TC IDs'

  foreach ($module in $report.modules) {
    Assert-True `
      -Condition (@('MAPPED', 'N/A', 'GAP') -contains $module.status) `
      -Message "Invalid module status for $($module.id): $($module.status)"

    $isAutomatedOnly = $module.id -eq 'M10' -or $module.id -eq 'M11'
    if ($isAutomatedOnly) {
      Assert-Equal -Actual $module.required_channel -Expected 'automated-only' -Label "$($module.id) channel"
      Assert-Equal -Actual $module.e2e_applicability -Expected 'N/A' -Label "$($module.id) E2E applicability"
      Assert-Equal -Actual $module.status -Expected 'N/A' -Label "$($module.id) module status"
      Assert-Equal -Actual @($module.matrix_cases).Count -Expected 0 -Label "$($module.id) E2E case count"
      Assert-True `
        -Condition (@($module.automated_test_candidates).Count -gt 0) `
        -Message "$($module.id) must retain automated test candidates."
    } else {
      Assert-Equal -Actual $module.e2e_applicability -Expected 'REQUIRED' -Label "$($module.id) E2E applicability"
    }
  }

  foreach ($item in $report.bd_acceptance) {
    Assert-True `
      -Condition (@('MAPPED', 'GAP') -contains $item.status) `
      -Message "Invalid BD status for $($item.id): $($item.status)"
    if ($item.status -eq 'MAPPED') {
      Assert-True `
        -Condition (@($item.mapped_cases).Count -gt 0) `
        -Message "$($item.id) is MAPPED without an exact matrix case."
    }
  }

  $traceItems = @($report.dd_acceptance) + @($report.overall_tests)
  foreach ($item in $traceItems) {
    Assert-True `
      -Condition (@('MAPPED', 'GAP') -contains $item.status) `
      -Message "Invalid trace status for $($item.id): $($item.status)"

    $isAutomatedOnly = $item.module -eq 'M10' -or $item.module -eq 'M11'
    if ($isAutomatedOnly) {
      Assert-Equal -Actual $item.e2e_applicability -Expected 'N/A' -Label "$($item.id) E2E applicability"
      if ($item.status -eq 'MAPPED') {
        Assert-True `
          -Condition (@($item.mapped_tests).Count -gt 0) `
          -Message "$($item.id) is automated-only and cannot be MAPPED without an exact test citation."
      }
    } else {
      Assert-Equal -Actual $item.e2e_applicability -Expected 'REQUIRED' -Label "$($item.id) E2E applicability"
      if ($item.status -eq 'MAPPED') {
        $mappingCount = @($item.mapped_cases).Count + @($item.mapped_tests).Count
        Assert-True `
          -Condition ($mappingCount -gt 0) `
          -Message "$($item.id) is MAPPED without an exact case/test citation."
      }
    }
  }

  $m10M11Cases = @(
    $report.matrix_cases |
      Where-Object { $_.module -eq 'M10' -or $_.module -eq 'M11' }
  )
  Assert-Equal -Actual $m10M11Cases.Count -Expected 0 -Label 'M10/M11 E2E matrix cases'

  Write-Host (
    'Regression traceability check PASS: 19 modules, 24 BD ACs, 494 DD acceptance IDs, 38 Overall TC IDs.'
  )
}
finally {
  foreach ($temporaryPath in @($temporaryMarkdown, $temporaryJson)) {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
      Remove-Item -LiteralPath $temporaryPath -Force
    }
  }
}
