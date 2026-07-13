[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$OutputPath,
  [string]$JsonOutputPath,
  [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ExpectedModuleCount = 19
$script:ExpectedBdAcceptanceCount = 24
$script:ExpectedFeatureAcceptanceCount = 152
$script:ExpectedFunctionAcceptanceCount = 190
$script:ExpectedViewAcceptanceCount = 152
$script:ExpectedDdAcceptanceCount = 494
$script:ExpectedOverallTestCount = 38

function Resolve-AbsolutePath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$BasePath
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }

  return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Assert-FileExists {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Required file was not found: $Path"
  }
}

function Read-Utf8Text {
  param([Parameter(Mandatory = $true)][string]$Path)

  Assert-FileExists -Path $Path
  return [System.IO.File]::ReadAllText(
    $Path,
    [System.Text.Encoding]::UTF8
  )
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
  )

  $directory = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($directory)) {
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  }

  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-RepoRelativePath {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Path
  )

  $rootFull = [System.IO.Path]::GetFullPath($Root)
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $separator = [System.IO.Path]::DirectorySeparatorChar
  $rootPrefix = $rootFull.TrimEnd([char[]]'\/') + $separator

  if (-not $pathFull.StartsWith(
      $rootPrefix,
      [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Path is outside repository root: $pathFull"
  }

  return $pathFull.Substring($rootPrefix.Length).Replace('\', '/')
}

function Escape-MarkdownCell {
  param([AllowNull()][string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return '-'
  }

  return $Value.Replace('|', '\|').Replace("`r", '').Replace("`n", '<br>')
}

function Add-MapValue {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Map,
    [Parameter(Mandatory = $true)][string]$Key,
    [Parameter(Mandatory = $true)][string]$Value
  )

  if (-not $Map.ContainsKey($Key)) {
    $Map[$Key] = New-Object 'System.Collections.Generic.List[string]'
  }

  if (-not $Map[$Key].Contains($Value)) {
    $Map[$Key].Add($Value)
  }
}

function Get-SortedMapValues {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Map,
    [Parameter(Mandatory = $true)][string]$Key
  )

  if (-not $Map.ContainsKey($Key)) {
    return @()
  }

  return @($Map[$Key] | Sort-Object -Unique)
}

function Get-TableIds {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Pattern
  )

  $values = New-Object 'System.Collections.Generic.List[string]'
  foreach ($match in [regex]::Matches($Text, $Pattern)) {
    $value = $match.Groups['id'].Value
    if (-not $values.Contains($value)) {
      $values.Add($value)
    }
  }

  return @($values | Sort-Object)
}

function Get-AcIdsFromCoverage {
  param([Parameter(Mandatory = $true)][string]$Coverage)

  $ids = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($match in [regex]::Matches($Coverage, '(?<![A-Z0-9-])AC-(\d{2})(?![0-9])')) {
    [void]$ids.Add(('AC-{0}' -f $match.Groups[1].Value))
  }

  $rangePattern = 'AC-(\d{2})\s*(?:\.\.|-|\u2013|\u2014)\s*(?:AC-)?(\d{2})'
  foreach ($match in [regex]::Matches($Coverage, $rangePattern)) {
    $start = [int]$match.Groups[1].Value
    $end = [int]$match.Groups[2].Value
    if ($end -lt $start) {
      throw "Invalid AC range in matrix coverage: $($match.Value)"
    }

    foreach ($number in $start..$end) {
      [void]$ids.Add(('AC-{0:D2}' -f $number))
    }
  }

  return @($ids | Sort-Object)
}

function Get-StatusCount {
  param(
    [Parameter(Mandatory = $true)][object[]]$Items,
    [Parameter(Mandatory = $true)][string]$Status
  )

  return @($Items | Where-Object { $_.status -eq $Status }).Count
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot '../..'
}
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = 'docs/test/v2-admin-regression/002-traceability-bd-dd-cases.md'
}
if ([string]::IsNullOrWhiteSpace($JsonOutputPath)) {
  $JsonOutputPath = 'docs/test/v2-admin-regression/002-traceability-bd-dd-cases.json'
}

$OutputPath = Resolve-AbsolutePath -Path $OutputPath -BasePath $RepoRoot
$JsonOutputPath = Resolve-AbsolutePath -Path $JsonOutputPath -BasePath $RepoRoot

$ddIndexPath = Join-Path $RepoRoot 'docs/DD/README.md'
$bdPath = Join-Path $RepoRoot 'docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md'
$matrixPath = Join-Path $RepoRoot 'docs/test/v2-admin-regression/001-test-v2-admin-regression.md'
$ddIndexText = Read-Utf8Text -Path $ddIndexPath
$bdText = Read-Utf8Text -Path $bdPath
$matrixText = Read-Utf8Text -Path $matrixPath

$modules = New-Object 'System.Collections.Generic.List[object]'
$modulePattern = '(?m)^\|\s*(?<id>M\d{2})\s*\|\s*\[(?<name>[^\]]+)\]\(\./(?<folder>[^/]+)/README\.md\)\s*\|\s*(?<code>[A-Z0-9_]+)\s*\|'
foreach ($match in [regex]::Matches($ddIndexText, $modulePattern)) {
  $modules.Add([pscustomobject][ordered]@{
      id = $match.Groups['id'].Value
      name = $match.Groups['name'].Value
      folder = $match.Groups['folder'].Value
      code = $match.Groups['code'].Value
    })
}
$modules = @($modules | Sort-Object id)

if ($modules.Count -ne $script:ExpectedModuleCount) {
  throw "Expected $($script:ExpectedModuleCount) DD modules, found $($modules.Count)."
}

$expectedModuleIds = @(1..$script:ExpectedModuleCount | ForEach-Object { 'M{0:D2}' -f $_ })
$actualModuleIds = @($modules | ForEach-Object { $_.id })
if (($actualModuleIds -join ',') -ne ($expectedModuleIds -join ',')) {
  throw "DD module IDs are not the canonical M01-M19 sequence."
}

$bdAcceptances = New-Object 'System.Collections.Generic.List[object]'
$bdAcceptancePattern = '(?m)^\|\s*(?<id>AC-\d{2})\s*\|\s*(?<scenario>.*?)\s*\|\s*(?<expected>.*?)\s*\|\s*$'
foreach ($match in [regex]::Matches($bdText, $bdAcceptancePattern)) {
  $bdAcceptances.Add([pscustomobject][ordered]@{
      id = $match.Groups['id'].Value
      scenario = $match.Groups['scenario'].Value.Trim()
      expected = $match.Groups['expected'].Value.Trim()
    })
}
$bdAcceptances = @($bdAcceptances | Sort-Object id -Unique)
if ($bdAcceptances.Count -ne $script:ExpectedBdAcceptanceCount) {
  throw "Expected $($script:ExpectedBdAcceptanceCount) BD ACs, found $($bdAcceptances.Count)."
}

$ddAcceptanceInventory = New-Object 'System.Collections.Generic.List[object]'
$overallTestInventory = New-Object 'System.Collections.Generic.List[object]'

foreach ($module in $modules) {
  $moduleRoot = Join-Path $RepoRoot ('docs/DD/{0}' -f $module.folder)
  $featurePath = Join-Path $moduleRoot 'List_Features.md'
  $functionPath = Join-Path $moduleRoot 'Function_List.md'
  $viewPath = Join-Path $moduleRoot 'Views.md'
  $overallPath = Join-Path $moduleRoot 'Overall.md'

  $featureText = Read-Utf8Text -Path $featurePath
  $functionText = Read-Utf8Text -Path $functionPath
  $viewText = Read-Utf8Text -Path $viewPath
  $overallText = Read-Utf8Text -Path $overallPath
  $prefix = [regex]::Escape($module.code)

  $featureIds = Get-TableIds -Text $featureText -Pattern (
    '(?m)^\|\s*(?<id>{0}-AC\d{{2}}-\d{{2}})\s*\|' -f $prefix
  )
  $functionIds = Get-TableIds -Text $functionText -Pattern (
    '(?m)^\|\s*(?<id>{0}-FN-EV\d{{2}}-\d{{2}})\s*\|' -f $prefix
  )
  $viewIds = Get-TableIds -Text $viewText -Pattern (
    '(?m)^\|\s*(?<id>{0}-VIEW-EV\d{{2}}-\d{{2}})\s*\|' -f $prefix
  )
  $overallIds = Get-TableIds -Text $overallText -Pattern (
    '(?m)\|\s*(?<id>{0}-TC\d{{2}})\s*\|\s*$' -f $prefix
  )

  foreach ($id in $featureIds) {
    $ddAcceptanceInventory.Add([pscustomobject][ordered]@{
        id = $id
        module = $module.id
        module_code = $module.code
        kind = 'feature'
        source = Get-RepoRelativePath -Root $RepoRoot -Path $featurePath
      })
  }
  foreach ($id in $functionIds) {
    $ddAcceptanceInventory.Add([pscustomobject][ordered]@{
        id = $id
        module = $module.id
        module_code = $module.code
        kind = 'function'
        source = Get-RepoRelativePath -Root $RepoRoot -Path $functionPath
      })
  }
  foreach ($id in $viewIds) {
    $ddAcceptanceInventory.Add([pscustomobject][ordered]@{
        id = $id
        module = $module.id
        module_code = $module.code
        kind = 'view'
        source = Get-RepoRelativePath -Root $RepoRoot -Path $viewPath
      })
  }
  foreach ($id in $overallIds) {
    $overallTestInventory.Add([pscustomobject][ordered]@{
        id = $id
        module = $module.id
        module_code = $module.code
        source = Get-RepoRelativePath -Root $RepoRoot -Path $overallPath
      })
  }
}

$ddAcceptanceInventory = @($ddAcceptanceInventory | Sort-Object module, kind, id)
$overallTestInventory = @($overallTestInventory | Sort-Object module, id)

$featureCount = @($ddAcceptanceInventory | Where-Object { $_.kind -eq 'feature' }).Count
$functionCount = @($ddAcceptanceInventory | Where-Object { $_.kind -eq 'function' }).Count
$viewCount = @($ddAcceptanceInventory | Where-Object { $_.kind -eq 'view' }).Count

if ($featureCount -ne $script:ExpectedFeatureAcceptanceCount) {
  throw "Expected $($script:ExpectedFeatureAcceptanceCount) feature acceptance IDs, found $featureCount."
}
if ($functionCount -ne $script:ExpectedFunctionAcceptanceCount) {
  throw "Expected $($script:ExpectedFunctionAcceptanceCount) function acceptance IDs, found $functionCount."
}
if ($viewCount -ne $script:ExpectedViewAcceptanceCount) {
  throw "Expected $($script:ExpectedViewAcceptanceCount) view acceptance IDs, found $viewCount."
}
if ($ddAcceptanceInventory.Count -ne $script:ExpectedDdAcceptanceCount) {
  throw "Expected $($script:ExpectedDdAcceptanceCount) DD acceptance IDs, found $($ddAcceptanceInventory.Count)."
}
if ($overallTestInventory.Count -ne $script:ExpectedOverallTestCount) {
  throw "Expected $($script:ExpectedOverallTestCount) Overall TC IDs, found $($overallTestInventory.Count)."
}

$inventoryIds = @(
  $ddAcceptanceInventory | ForEach-Object { $_.id }
  $overallTestInventory | ForEach-Object { $_.id }
)
if (@($inventoryIds | Sort-Object -Unique).Count -ne $inventoryIds.Count) {
  throw 'Duplicate DD acceptance or Overall TC IDs were found.'
}
$inventoryIdSet = @{}
foreach ($id in $inventoryIds) {
  $inventoryIdSet[$id] = $true
}

$matrixCases = New-Object 'System.Collections.Generic.List[object]'
$caseToDdIds = @{}
$acToCases = @{}
$ddIdToCases = @{}
$casePattern = '^\|\s*(?<id>(?:PRE-\d{2}|(?:V2|ADMIN)-M\d{2}-\d{2}))\s*\|\s*(?<persona>.*?)\s*\|\s*(?<scenario>.*?)\s*\|\s*(?<coverage>.*?)\s*\|\s*(?<image>.*?)\s*\|\s*(?<note>.*?)\s*\|\s*(?<status>.*?)\s*\|\s*$'
$traceIdPattern = '\b[A-Z][A-Z0-9_]+-(?:AC\d{2}-\d{2}|FN-EV\d{2}-\d{2}|VIEW-EV\d{2}-\d{2}|TC\d{2})\b'

foreach ($line in [regex]::Split($matrixText, '\r?\n')) {
  $match = [regex]::Match($line, $casePattern)
  if (-not $match.Success) {
    continue
  }

  $caseId = $match.Groups['id'].Value
  $coverage = $match.Groups['coverage'].Value.Trim()
  $moduleId = $null
  $moduleMatch = [regex]::Match($caseId, '-(M\d{2})-')
  if ($moduleMatch.Success) {
    $moduleId = $moduleMatch.Groups[1].Value
  }

  $referencedDdIds = New-Object 'System.Collections.Generic.List[string]'
  foreach ($idMatch in [regex]::Matches($line, $traceIdPattern)) {
    $traceId = $idMatch.Value
    if ($inventoryIdSet.ContainsKey($traceId) -and -not $referencedDdIds.Contains($traceId)) {
      $referencedDdIds.Add($traceId)
      Add-MapValue -Map $ddIdToCases -Key $traceId -Value $caseId
    }
  }
  $caseToDdIds[$caseId] = @($referencedDdIds | Sort-Object)

  foreach ($acId in (Get-AcIdsFromCoverage -Coverage $coverage)) {
    Add-MapValue -Map $acToCases -Key $acId -Value $caseId
  }

  $matrixCases.Add([pscustomobject][ordered]@{
      id = $caseId
      module = $moduleId
      coverage = $coverage
      status = $match.Groups['status'].Value.Trim()
      exact_dd_ids = @($referencedDdIds | Sort-Object)
    })
}
$matrixCases = @($matrixCases | Sort-Object id)

if (@($matrixCases | ForEach-Object { $_.id } | Sort-Object -Unique).Count -ne $matrixCases.Count) {
  throw 'Duplicate regression case IDs were found in the matrix.'
}

$ddIdToTests = @{}
$testFiles = @()
$testRoot = Join-Path $RepoRoot 'test'
if (Test-Path -LiteralPath $testRoot -PathType Container) {
  $testFiles = @(
    Get-ChildItem -LiteralPath $testRoot -Recurse -File -Filter '*.dart' |
      Sort-Object FullName
  )
}

foreach ($testFile in $testFiles) {
  $testText = Read-Utf8Text -Path $testFile.FullName
  $relativeTestPath = Get-RepoRelativePath -Root $RepoRoot -Path $testFile.FullName
  foreach ($idMatch in [regex]::Matches($testText, $traceIdPattern)) {
    $traceId = $idMatch.Value
    if ($inventoryIdSet.ContainsKey($traceId)) {
      Add-MapValue -Map $ddIdToTests -Key $traceId -Value $relativeTestPath
    }
  }
}

$moduleResults = New-Object 'System.Collections.Generic.List[object]'
foreach ($module in $modules) {
  $isAutomatedOnly = $module.id -eq 'M10' -or $module.id -eq 'M11'
  $moduleCases = @(
    $matrixCases |
      Where-Object { $_.module -eq $module.id } |
      ForEach-Object { $_.id }
  )
  $candidatePrefix = if ($module.id -eq 'M10') {
    'test/app_versions/v3/features/advanced_tracking/'
  } elseif ($module.id -eq 'M11') {
    'test/app_versions/v3/features/familyplus/'
  } else {
    $null
  }
  $automatedCandidates = @()
  if ($null -ne $candidatePrefix) {
    $automatedCandidates = @(
      $testFiles |
        ForEach-Object { Get-RepoRelativePath -Root $RepoRoot -Path $_.FullName } |
        Where-Object { $_.StartsWith($candidatePrefix, [System.StringComparison]::OrdinalIgnoreCase) } |
        Sort-Object
    )
  }

  if ($isAutomatedOnly -and $moduleCases.Count -gt 0) {
    throw "$($module.id) is automated-only but has E2E matrix cases: $($moduleCases -join ', ')."
  }

  $channel = if ($isAutomatedOnly) {
    'automated-only'
  } elseif ([int]$module.id.Substring(1) -ge 15) {
    'Admin E2E'
  } else {
    'v2 E2E'
  }
  $e2eApplicability = if ($isAutomatedOnly) { 'N/A' } else { 'REQUIRED' }
  $status = if ($isAutomatedOnly) {
    'N/A'
  } elseif ($moduleCases.Count -gt 0) {
    'MAPPED'
  } else {
    'GAP'
  }

  $moduleResults.Add([pscustomobject][ordered]@{
      id = $module.id
      name = $module.name
      code = $module.code
      folder = $module.folder
      required_channel = $channel
      e2e_applicability = $e2eApplicability
      status = $status
      matrix_cases = @($moduleCases)
      automated_test_candidates = @($automatedCandidates)
    })
}
$moduleResults = @($moduleResults | Sort-Object id)

$bdAcceptanceResults = New-Object 'System.Collections.Generic.List[object]'
foreach ($acceptance in $bdAcceptances) {
  $mappedCases = Get-SortedMapValues -Map $acToCases -Key $acceptance.id
  $status = if ($mappedCases.Count -gt 0) { 'MAPPED' } else { 'GAP' }
  $bdAcceptanceResults.Add([pscustomobject][ordered]@{
      id = $acceptance.id
      scenario = $acceptance.scenario
      expected = $acceptance.expected
      status = $status
      mapped_cases = @($mappedCases)
    })
}
$bdAcceptanceResults = @($bdAcceptanceResults | Sort-Object id)

$ddAcceptanceResults = New-Object 'System.Collections.Generic.List[object]'
foreach ($item in $ddAcceptanceInventory) {
  $mappedCases = Get-SortedMapValues -Map $ddIdToCases -Key $item.id
  $mappedTests = Get-SortedMapValues -Map $ddIdToTests -Key $item.id
  $isAutomatedOnly = $item.module -eq 'M10' -or $item.module -eq 'M11'
  $status = if ($isAutomatedOnly) {
    if ($mappedTests.Count -gt 0) { 'MAPPED' } else { 'GAP' }
  } elseif ($mappedCases.Count -gt 0 -or $mappedTests.Count -gt 0) {
    'MAPPED'
  } else {
    'GAP'
  }

  $ddAcceptanceResults.Add([pscustomobject][ordered]@{
      id = $item.id
      module = $item.module
      module_code = $item.module_code
      kind = $item.kind
      source = $item.source
      required_channel = if ($isAutomatedOnly) { 'automated-only' } else { 'E2E or exact automated test' }
      e2e_applicability = if ($isAutomatedOnly) { 'N/A' } else { 'REQUIRED' }
      status = $status
      mapped_cases = @($mappedCases)
      mapped_tests = @($mappedTests)
    })
}
$ddAcceptanceResults = @($ddAcceptanceResults | Sort-Object module, kind, id)

$overallTestResults = New-Object 'System.Collections.Generic.List[object]'
foreach ($item in $overallTestInventory) {
  $mappedCases = Get-SortedMapValues -Map $ddIdToCases -Key $item.id
  $mappedTests = Get-SortedMapValues -Map $ddIdToTests -Key $item.id
  $isAutomatedOnly = $item.module -eq 'M10' -or $item.module -eq 'M11'
  $status = if ($isAutomatedOnly) {
    if ($mappedTests.Count -gt 0) { 'MAPPED' } else { 'GAP' }
  } elseif ($mappedCases.Count -gt 0 -or $mappedTests.Count -gt 0) {
    'MAPPED'
  } else {
    'GAP'
  }

  $overallTestResults.Add([pscustomobject][ordered]@{
      id = $item.id
      module = $item.module
      module_code = $item.module_code
      source = $item.source
      required_channel = if ($isAutomatedOnly) { 'automated-only' } else { 'E2E or exact automated test' }
      e2e_applicability = if ($isAutomatedOnly) { 'N/A' } else { 'REQUIRED' }
      status = $status
      mapped_cases = @($mappedCases)
      mapped_tests = @($mappedTests)
    })
}
$overallTestResults = @($overallTestResults | Sort-Object module, id)

$report = [pscustomobject][ordered]@{
  schema_version = 1
  generated_by = 'tools/regression/New-RegressionTraceability.ps1'
  sources = [pscustomobject][ordered]@{
    bd = Get-RepoRelativePath -Root $RepoRoot -Path $bdPath
    dd_index = Get-RepoRelativePath -Root $RepoRoot -Path $ddIndexPath
    regression_matrix = Get-RepoRelativePath -Root $RepoRoot -Path $matrixPath
  }
  expected_counts = [pscustomobject][ordered]@{
    modules = $script:ExpectedModuleCount
    bd_acceptance = $script:ExpectedBdAcceptanceCount
    dd_feature_acceptance = $script:ExpectedFeatureAcceptanceCount
    dd_function_acceptance = $script:ExpectedFunctionAcceptanceCount
    dd_view_acceptance = $script:ExpectedViewAcceptanceCount
    dd_acceptance_total = $script:ExpectedDdAcceptanceCount
    overall_tests = $script:ExpectedOverallTestCount
  }
  summary = [pscustomobject][ordered]@{
    modules = $moduleResults.Count
    regression_cases = $matrixCases.Count
    bd_acceptance = $bdAcceptanceResults.Count
    bd_mapped = Get-StatusCount -Items $bdAcceptanceResults -Status 'MAPPED'
    bd_gaps = Get-StatusCount -Items $bdAcceptanceResults -Status 'GAP'
    dd_acceptance = $ddAcceptanceResults.Count
    dd_mapped = Get-StatusCount -Items $ddAcceptanceResults -Status 'MAPPED'
    dd_gaps = Get-StatusCount -Items $ddAcceptanceResults -Status 'GAP'
    overall_tests = $overallTestResults.Count
    overall_mapped = Get-StatusCount -Items $overallTestResults -Status 'MAPPED'
    overall_gaps = Get-StatusCount -Items $overallTestResults -Status 'GAP'
  }
  modules = @($moduleResults)
  bd_acceptance = @($bdAcceptanceResults)
  dd_acceptance = @($ddAcceptanceResults)
  overall_tests = @($overallTestResults)
  matrix_cases = @($matrixCases)
}

$markdown = New-Object 'System.Collections.Generic.List[string]'
$markdown.Add('<!-- Generated by tools/regression/New-RegressionTraceability.ps1. Do not edit manually. -->')
$markdown.Add('')
$markdown.Add('# Traceability - BD, DD, and v2/Admin regression cases')
$markdown.Add('')
$markdown.Add('This report is deterministic and source-driven. `MAPPED` means an exact requirement ID is cited by a regression case or automated test; it does not mean the case has passed. Module-level `MAPPED` only means that the module has catalog cases and never implies that all DD requirements are covered.')
$markdown.Add('')
$markdown.Add('- `N/A` is limited to E2E applicability for M10/M11. Both modules remain mandatory through automated tests.')
$markdown.Add('- `GAP` means no exact case/test citation exists for the required ID. Similar wording or a case in the same module is not treated as coverage.')
$markdown.Add('- Current matrix execution states such as `PENDING` remain authoritative in `001-test-v2-admin-regression.md`.')
$markdown.Add('')
$markdown.Add('## Sources')
$markdown.Add('')
$markdown.Add(('- BD: `{0}`' -f $report.sources.bd))
$markdown.Add(('- DD index: `{0}`' -f $report.sources.dd_index))
$markdown.Add(('- Regression matrix: `{0}`' -f $report.sources.regression_matrix))
$markdown.Add('')
$markdown.Add('## Inventory summary')
$markdown.Add('')
$markdown.Add('| Inventory | Total | Mapped | Gap | N/A rule |')
$markdown.Add('|---|---:|---:|---:|---|')
$markdown.Add(('| Modules M01-M19 | {0} | {1} | {2} | M10/M11 E2E only |' -f
    $report.summary.modules,
    (Get-StatusCount -Items $moduleResults -Status 'MAPPED'),
    (Get-StatusCount -Items $moduleResults -Status 'GAP')))
$markdown.Add(('| BD AC-01..AC-24 | {0} | {1} | {2} | None |' -f
    $report.summary.bd_acceptance,
    $report.summary.bd_mapped,
    $report.summary.bd_gaps))
$markdown.Add(('| DD feature acceptance | {0} | {1} | {2} | M10/M11 E2E column only |' -f
    $featureCount,
    @($ddAcceptanceResults | Where-Object { $_.kind -eq 'feature' -and $_.status -eq 'MAPPED' }).Count,
    @($ddAcceptanceResults | Where-Object { $_.kind -eq 'feature' -and $_.status -eq 'GAP' }).Count))
$markdown.Add(('| DD function acceptance | {0} | {1} | {2} | M10/M11 E2E column only |' -f
    $functionCount,
    @($ddAcceptanceResults | Where-Object { $_.kind -eq 'function' -and $_.status -eq 'MAPPED' }).Count,
    @($ddAcceptanceResults | Where-Object { $_.kind -eq 'function' -and $_.status -eq 'GAP' }).Count))
$markdown.Add(('| DD view acceptance | {0} | {1} | {2} | M10/M11 E2E column only |' -f
    $viewCount,
    @($ddAcceptanceResults | Where-Object { $_.kind -eq 'view' -and $_.status -eq 'MAPPED' }).Count,
    @($ddAcceptanceResults | Where-Object { $_.kind -eq 'view' -and $_.status -eq 'GAP' }).Count))
$markdown.Add(('| DD acceptance total | {0} | {1} | {2} | M10/M11 E2E column only |' -f
    $report.summary.dd_acceptance,
    $report.summary.dd_mapped,
    $report.summary.dd_gaps))
$markdown.Add(('| Overall TC IDs | {0} | {1} | {2} | M10/M11 E2E column only |' -f
    $report.summary.overall_tests,
    $report.summary.overall_mapped,
    $report.summary.overall_gaps))
$markdown.Add(('| Regression catalog cases | {0} | - | - | Six preflight cases included |' -f
    $report.summary.regression_cases))
$markdown.Add('')
$markdown.Add('## Module scope and catalog mapping')
$markdown.Add('')
$markdown.Add('| Module | DD code | Required channel | E2E | Catalog cases | Automated candidates | Status |')
$markdown.Add('|---|---|---|---|---:|---:|---|')
foreach ($module in $moduleResults) {
  $markdown.Add(('| {0} - {1} | `{2}` | {3} | {4} | {5} | {6} | {7} |' -f
      $module.id,
      (Escape-MarkdownCell -Value $module.name),
      $module.code,
      $module.required_channel,
      $module.e2e_applicability,
      $module.matrix_cases.Count,
      $module.automated_test_candidates.Count,
      $module.status))
}
$markdown.Add('')
$markdown.Add('M10 and M11 deliberately have no E2E catalog cases and are not routes through `main.dart`. Their automated test files are candidates only; they become mapped evidence only when they cite the exact DD acceptance or Overall TC ID.')
$markdown.Add('')
$markdown.Add('## BD acceptance mapping')
$markdown.Add('')
$markdown.Add('| BD AC | Scenario | Exact matrix cases | Status |')
$markdown.Add('|---|---|---|---|')
foreach ($acceptance in $bdAcceptanceResults) {
  $cases = if ($acceptance.mapped_cases.Count -gt 0) {
    $acceptance.mapped_cases -join ', '
  } else {
    '-'
  }
  $markdown.Add(('| {0} | {1} | {2} | {3} |' -f
      $acceptance.id,
      (Escape-MarkdownCell -Value $acceptance.scenario),
      (Escape-MarkdownCell -Value $cases),
      $acceptance.status))
}
$markdown.Add('')
$markdown.Add('## DD feature/function/view acceptance inventory')
$markdown.Add('')

foreach ($module in $moduleResults) {
  $moduleItems = @($ddAcceptanceResults | Where-Object { $_.module -eq $module.id })
  $markdown.Add(('### {0} - {1}' -f $module.id, $module.name))
  $markdown.Add('')
  $markdown.Add('| DD acceptance ID | Kind | Required channel | E2E | Exact cases | Exact tests | Status |')
  $markdown.Add('|---|---|---|---|---|---|---|')
  foreach ($item in $moduleItems) {
    $cases = if ($item.mapped_cases.Count -gt 0) { $item.mapped_cases -join ', ' } else { '-' }
    $tests = if ($item.mapped_tests.Count -gt 0) { $item.mapped_tests -join '<br>' } else { '-' }
    $markdown.Add(('| `{0}` | {1} | {2} | {3} | {4} | {5} | {6} |' -f
        $item.id,
        $item.kind,
        $item.required_channel,
        $item.e2e_applicability,
        (Escape-MarkdownCell -Value $cases),
        (Escape-MarkdownCell -Value $tests),
        $item.status))
  }
  $markdown.Add('')
}

$markdown.Add('## Overall TC inventory')
$markdown.Add('')
$markdown.Add('| Overall TC ID | Module | Required channel | E2E | Exact cases | Exact tests | Status |')
$markdown.Add('|---|---|---|---|---|---|---|')
foreach ($item in $overallTestResults) {
  $cases = if ($item.mapped_cases.Count -gt 0) { $item.mapped_cases -join ', ' } else { '-' }
  $tests = if ($item.mapped_tests.Count -gt 0) { $item.mapped_tests -join '<br>' } else { '-' }
  $markdown.Add(('| `{0}` | {1} | {2} | {3} | {4} | {5} | {6} |' -f
      $item.id,
      $item.module,
      $item.required_channel,
      $item.e2e_applicability,
      (Escape-MarkdownCell -Value $cases),
      (Escape-MarkdownCell -Value $tests),
      $item.status))
}
$markdown.Add('')
$markdown.Add('## Gap interpretation')
$markdown.Add('')
$markdown.Add('The generated gaps are intentional audit output, not inferred failures of runtime behavior. Close a gap by adding the exact DD acceptance/Overall TC ID to the responsible regression case or automated test. Regenerate this report afterward; do not manually change a status here.')
$markdown.Add('')
$markdown.Add('The machine-readable companion is `002-traceability-bd-dd-cases.json`.')
$markdown.Add('')

$markdownText = ($markdown -join "`n")
$jsonText = ($report | ConvertTo-Json -Depth 10)
$jsonText = $jsonText.Replace("`r`n", "`n") + "`n"

Write-Utf8NoBom -Path $OutputPath -Content $markdownText
Write-Utf8NoBom -Path $JsonOutputPath -Content $jsonText

Write-Host (
  'Traceability generated: modules={0}, BD_AC={1}, DD_acceptance={2}, Overall_TC={3}, cases={4}.' -f
  $moduleResults.Count,
  $bdAcceptanceResults.Count,
  $ddAcceptanceResults.Count,
  $overallTestResults.Count,
  $matrixCases.Count
)

if ($PassThru) {
  Write-Output $report
}
