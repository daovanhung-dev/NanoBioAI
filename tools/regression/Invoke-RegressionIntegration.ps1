[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('v2', 'admin')]
  [string]$Surface,

  [ValidateNotNullOrEmpty()]
  [string]$CaseId = 'PRE-02',

  [ValidateNotNullOrEmpty()]
  [string]$DeviceId = '12b304f9',

  [ValidateNotNullOrEmpty()]
  [string]$EnvFile = '.env',

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$ExpectedSandboxProjectRef,

  [switch]$ResetState,

  [ValidateSet('', 'YES')]
  [string]$ConfirmStateReset = '',

  [switch]$AllowEvidenceOverwrite
)

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

$case = Get-RegressionCase -CaseId $CaseId
if ($case.CaseId -ne 'PRE-02') {
  throw 'The current smoke targets certify PRE-02 only.'
}
$resolvedEnv = Resolve-RegressionRepoFile -Path $EnvFile -Label 'Environment'
& powershell -ExecutionPolicy Bypass -File `
  (Join-Path $script:RegressionRepoRoot 'tools/run_v2.ps1') `
  -EnvFile $resolvedEnv `
  -EntryPoint 'lib/main.dart' `
  -ValidateOnly
if ($LASTEXITCODE -ne 0) {
  throw 'Environment validation failed.'
}

$sandboxFingerprint = Assert-RegressionSandboxProject `
  -EnvFile $resolvedEnv `
  -ExpectedProjectRef $ExpectedSandboxProjectRef
$device = Get-RegressionDeviceMetadata -DeviceId $DeviceId

if ($ResetState) {
  if ($ConfirmStateReset -ne 'YES') {
    throw 'State reset requires -ConfirmStateReset YES.'
  }
  & adb -s $DeviceId shell pm clear $script:RegressionPackageName
  if ($LASTEXITCODE -ne 0) {
    throw 'Local Android application-state reset failed.'
  }
}

$target = if ($Surface -eq 'v2') {
  'integration_test/v2/preflight_smoke_test.dart'
} else {
  'integration_test/admin/preflight_smoke_test.dart'
}
$commandId = New-RegressionCommandId -Surface $Surface -CaseId $CaseId
$startedAt = (Get-Date).ToUniversalTime()
$exitCode = $null

$previousEvidenceRoot = $env:NANOBIO_EVIDENCE_ROOT
$previousCommandId = $env:NANOBIO_TEST_COMMAND_ID
$previousOverwrite = $env:NANOBIO_EVIDENCE_ALLOW_OVERWRITE
$debugWasDefined = Test-Path Env:DEBUG
$previousDebug = if ($debugWasDefined) { $env:DEBUG } else { $null }

try {
  $env:NANOBIO_EVIDENCE_ROOT = $script:RegressionEvidenceRoot
  $env:NANOBIO_TEST_COMMAND_ID = $commandId
  $env:NANOBIO_EVIDENCE_ALLOW_OVERWRITE = if ($AllowEvidenceOverwrite) {
    'YES'
  } else {
    'NO'
  }
  Remove-Item Env:DEBUG -ErrorAction SilentlyContinue

  Push-Location $script:RegressionRepoRoot
  try {
    & flutter drive `
      -d $DeviceId `
      --driver test_driver/evidence_driver.dart `
      --target $target `
      --dart-define-from-file=$resolvedEnv `
      --dart-define=REGRESSION_CASE_ID=$CaseId
    $exitCode = $LASTEXITCODE
  } finally {
    Pop-Location
  }
} finally {
  if ($null -eq $previousEvidenceRoot) {
    Remove-Item Env:NANOBIO_EVIDENCE_ROOT -ErrorAction SilentlyContinue
  } else {
    $env:NANOBIO_EVIDENCE_ROOT = $previousEvidenceRoot
  }
  if ($null -eq $previousCommandId) {
    Remove-Item Env:NANOBIO_TEST_COMMAND_ID -ErrorAction SilentlyContinue
  } else {
    $env:NANOBIO_TEST_COMMAND_ID = $previousCommandId
  }
  if ($null -eq $previousOverwrite) {
    Remove-Item Env:NANOBIO_EVIDENCE_ALLOW_OVERWRITE -ErrorAction SilentlyContinue
  } else {
    $env:NANOBIO_EVIDENCE_ALLOW_OVERWRITE = $previousOverwrite
  }
  if ($debugWasDefined) {
    $env:DEBUG = $previousDebug
  } else {
    Remove-Item Env:DEBUG -ErrorAction SilentlyContinue
  }
}

$finishedAt = (Get-Date).ToUniversalTime()
$runManifestPath = Join-Path $script:RegressionEvidenceRoot `
  "evidence/runs/$commandId-wrapper.json"
$manifest = [ordered]@{
  command_id = $commandId
  case_id = $CaseId
  surface = $Surface
  target = $target
  started_at = $startedAt.ToString('o')
  finished_at = $finishedAt.ToString('o')
  exit_code = $exitCode
  sandbox_ref_fingerprint = $sandboxFingerprint
  device = [ordered]@{
    id = $device.DeviceId
    android_api = $device.AndroidApi
    model = $device.Model
    resolution = $device.Resolution
  }
}
Write-RegressionUtf8File `
  -Path $runManifestPath `
  -Content ($manifest | ConvertTo-Json -Depth 5)

if ($exitCode -ne 0) {
  throw "Integration run failed. command_id=$commandId"
}

Write-Host "Integration evidence captured. command_id=$commandId"
Write-Host 'Review/redact the PNG, then finalize the case note explicitly.'
