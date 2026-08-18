param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$relative = 'lib\app_versions\v1\features\features_hub\presentation\pages\features_hub_page.dart'
$source = Join-Path $PSScriptRoot $relative
$target = Join-Path $ProjectRoot $relative

if (-not (Test-Path $source)) {
  throw "Không tìm thấy file patch: $source"
}

if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) {
  throw "ProjectRoot không phải root Flutter project: $ProjectRoot"
}

$targetDir = Split-Path -Parent $target
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if (Test-Path $target) {
  $backup = "$target.bak_featurehub"
  Copy-Item $target $backup -Force
  Write-Host "Backup: $backup"
}

Copy-Item $source $target -Force

$content = Get-Content $target -Raw
if ($content -notmatch "crossAxisCount = 3" -or $content -notmatch "active-features-grid") {
  throw 'File đã copy nhưng không tìm thấy marker compact 3-column.'
}

Write-Host ''
Write-Host 'Feature Hub fix đã được áp dụng.' -ForegroundColor Green
Write-Host 'Bắt buộc HOT RESTART hoặc dừng app và chạy lại. Không chỉ hot reload.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Khuyến nghị:'
Write-Host '  flutter clean'
Write-Host '  flutter pub get'
Write-Host '  flutter run'
