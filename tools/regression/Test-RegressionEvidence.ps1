[CmdletBinding()]
param([switch]$RequireComplete)

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

$cases = @(Get-RegressionCases)
$errors = New-Object System.Collections.Generic.List[string]
$allowedStatuses = @('PENDING', 'PASS', 'FAIL', 'BLOCKED', 'N/A')

if ($cases.Count -lt 111) {
  $errors.Add("Expected at least 111 cases, found $($cases.Count).") | Out-Null
}
$expectedAutomatedCounts = @{ M10 = 5; M11 = 5 }
foreach ($module in $expectedAutomatedCounts.Keys) {
  $count = @($cases | Where-Object { $_.CaseId -like "AUT-$module-*" }).Count
  if ($count -lt $expectedAutomatedCounts[$module]) {
    $errors.Add("Expected at least $($expectedAutomatedCounts[$module]) automated cases for $module, found $count.") | Out-Null
  }
}
$duplicates = @($cases | Group-Object CaseId | Where-Object { $_.Count -ne 1 })
foreach ($duplicate in $duplicates) {
  $errors.Add("Duplicate case ID: $($duplicate.Name)") | Out-Null
}

$matrixText = [System.IO.File]::ReadAllText($script:RegressionMatrixPath)
if ($matrixText -match '`AV`|View Admin') {
  $errors.Add('Deprecated View Admin persona remains in the matrix.') | Out-Null
}

foreach ($case in $cases) {
  if ($allowedStatuses -notcontains $case.Status) {
    $errors.Add("Invalid status for $($case.CaseId): $($case.Status)") | Out-Null
  }
  $expectedAsset = "assets/$($case.CaseId)-pass.png"
  $expectedEvidence = "evidence/$($case.CaseId).md"
  if ($case.AssetPath -ne $expectedAsset) {
    $errors.Add("Non-canonical asset path for $($case.CaseId).") | Out-Null
  }
  if ($case.EvidencePath -ne $expectedEvidence) {
    $errors.Add("Non-canonical evidence path for $($case.CaseId).") | Out-Null
  }

  if ($case.Status -eq 'PASS') {
    $assetPath = Join-Path $script:RegressionEvidenceRoot $expectedAsset
    $evidencePath = Join-Path $script:RegressionEvidenceRoot $expectedEvidence
    if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
      $errors.Add("PASS is missing main PNG: $($case.CaseId)") | Out-Null
    }
    if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
      $errors.Add("PASS is missing evidence note: $($case.CaseId)") | Out-Null
    } else {
      $note = [System.IO.File]::ReadAllText($evidencePath)
      if ($note -notmatch '(?m)^status:\s*PASS\s*$') {
        $errors.Add("PASS note status mismatch: $($case.CaseId)") | Out-Null
      }
      if ($note -notmatch '(?m)^\s+redacted:\s*true\s*$') {
        $errors.Add("PASS note lacks redaction confirmation: $($case.CaseId)") | Out-Null
      }
      if ($case.CaseId -notlike 'PRE-*' -and $note -match '(?m)^dd_refs:\s*\[\]\s*$') {
        $errors.Add("PASS note lacks DD reference: $($case.CaseId)") | Out-Null
      }
    }
  }
}

if ($RequireComplete) {
  foreach ($case in $cases | Where-Object { $_.Status -ne 'PASS' }) {
    $errors.Add("Campaign is incomplete: $($case.CaseId)=$($case.Status)") | Out-Null
  }
}

$statusSummary = $cases | Group-Object Status | Sort-Object Name
Write-Host "Regression cases: $($cases.Count)"
foreach ($group in $statusSummary) {
  Write-Host "  $($group.Name): $($group.Count)"
}
if ($errors.Count -gt 0) {
  foreach ($errorMessage in $errors) { Write-Error $errorMessage }
  throw "Regression evidence validation failed with $($errors.Count) error(s)."
}
Write-Host 'REGRESSION EVIDENCE VALIDATION PASSED'
