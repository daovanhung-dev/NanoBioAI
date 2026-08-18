param(
  [string]$ProjectRoot = (Get-Location).Path
)

$relative = 'lib\app_versions\v1\features\features_hub\presentation\pages\features_hub_page.dart'
$target = Join-Path $ProjectRoot $relative

if (-not (Test-Path $target)) {
  Write-Error "Không tìm thấy: $target"
  exit 1
}

$content = Get-Content $target -Raw
$checks = @(
  @{ Name = 'Stateful Feature Hub'; Pattern = 'class FeaturesHubPage extends StatefulWidget' },
  @{ Name = '3-column compact grid'; Pattern = 'crossAxisCount = 3' },
  @{ Name = 'Active grid key'; Pattern = 'active-features-grid' },
  @{ Name = 'Water tracking shortcut'; Pattern = "id: 'water-tracking'" },
  @{ Name = 'AI voice shortcut'; Pattern = "id: 'ai-voice'" },
  @{ Name = 'Collapsed planned section'; Pattern = '_plannedExpanded = false' },
  @{ Name = 'Collapsed advanced section'; Pattern = '_advancedExpanded = false' }
)

$failed = $false
foreach ($check in $checks) {
  if ($content -match $check.Pattern) {
    Write-Host "[PASS] $($check.Name)" -ForegroundColor Green
  } else {
    Write-Host "[FAIL] $($check.Name)" -ForegroundColor Red
    $failed = $true
  }
}

if ($failed) { exit 1 }
Write-Host 'Feature Hub source đúng bản compact.' -ForegroundColor Green
