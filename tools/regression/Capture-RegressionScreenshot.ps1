[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$CaseId,
  [ValidateNotNullOrEmpty()][string]$DeviceId = '12b304f9',
  [ValidateSet('pass', 'fail-before-fix')][string]$Kind = 'pass',
  [ValidatePattern('^[a-z0-9-]*$')][string]$Variant = '',
  [Parameter(Mandatory = $true)][ValidateSet('YES')]
  [string]$RedactionConfirmed,
  [switch]$Force
)

. (Join-Path $PSScriptRoot 'Regression.Common.ps1')

$null = Get-RegressionCase -CaseId $CaseId
$null = Get-RegressionDeviceMetadata -DeviceId $DeviceId
$suffix = if ([string]::IsNullOrWhiteSpace($Variant)) {
  $Kind
} else {
  "$Variant-$Kind"
}
$fileName = "$CaseId-$suffix.png"
$target = Assert-RegressionPathInsideRoot `
  -Path (Join-Path $script:RegressionEvidenceRoot "assets/$fileName") `
  -Root $script:RegressionEvidenceRoot
if ((Test-Path -LiteralPath $target -PathType Leaf) -and -not $Force) {
  throw 'Evidence image already exists; use -Force only for an explicit retest.'
}

$remoteName = "nanobio-regression-$([guid]::NewGuid().ToString('N')).png"
$remotePath = "/sdcard/$remoteName"
try {
  & adb -s $DeviceId shell screencap -p $remotePath
  if ($LASTEXITCODE -ne 0) { throw 'Android screenshot command failed.' }
  & adb -s $DeviceId pull $remotePath $target | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Android screenshot pull failed.' }
} finally {
  & adb -s $DeviceId shell rm -f $remotePath 2>$null
}

$bytes = [System.IO.File]::ReadAllBytes($target)
$pngSignature = @(137, 80, 78, 71, 13, 10, 26, 10)
if ($bytes.Length -lt 8) { throw 'Captured PNG is empty.' }
for ($index = 0; $index -lt 8; $index++) {
  if ($bytes[$index] -ne $pngSignature[$index]) {
    throw 'Captured file does not have a valid PNG signature.'
  }
}

$commandId = New-RegressionCommandId -Surface 'manual' -CaseId $CaseId
Write-Host "Screenshot captured: assets/$fileName"
Write-Host "command_id=$commandId"
