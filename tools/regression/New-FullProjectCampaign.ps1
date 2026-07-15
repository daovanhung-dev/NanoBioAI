[CmdletBinding()]
param(
  [string]$CampaignRoot = 'docs/test/15-07-2026',
  [string]$SourceMatrix = 'docs/test/v2-admin-regression/001-test-v2-admin-regression.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$root = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $CampaignRoot))
$testRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'docs/test'))
if (-not $root.StartsWith($testRoot + [IO.Path]::DirectorySeparatorChar)) {
  throw 'Campaign root must stay under docs/test.'
}
$matrix = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $SourceMatrix))
if (-not (Test-Path -LiteralPath $matrix -PathType Leaf)) {
  throw 'Source matrix was not found.'
}

$cases = @()
foreach ($line in [IO.File]::ReadAllLines($matrix)) {
  if ($line -notmatch '^\|\s*((PRE|V2|ADM|AUT)-[A-Z0-9-]+)\s*\|') { continue }
  $cells = @($line.Split('|') | ForEach-Object { $_.Trim() })
  if ($cells.Count -lt 8) { throw "Malformed matrix row: $($Matches[1])" }
  $cases += [pscustomobject]@{
    Id = $cells[1]
    Persona = $cells[2]
    Scenario = $cells[3]
    Refs = $cells[4]
  }
}
if ($cases.Count -eq 0) { throw 'No cases were found.' }

$utf8 = New-Object Text.UTF8Encoding($false)
$casesRoot = Join-Path $root 'cases'
$assetsRoot = Join-Path $root 'assets'
[IO.Directory]::CreateDirectory($casesRoot) | Out-Null
[IO.Directory]::CreateDirectory($assetsRoot) | Out-Null

foreach ($case in $cases) {
  $content = @"
Commit de xuat: test(real-device): ghi nhan case $($case.Id)

# $($case.Id)

- Trạng thái: PENDING
- Persona/tiền điều kiện: $($case.Persona)
- BD/DD/AC: $($case.Refs)
- Thiết bị bắt buộc: Xiaomi 220333QPG, Android 11/API 30, 720x1650

## Kịch bản và kết quả mong đợi

$($case.Scenario)

## Thao tác thực tế

- Chưa thực thi trong chiến dịch 15-07-2026.

## Kết quả thực tế

- Chưa có kết quả quan sát từ điện thoại thật.

## Bằng chứng

- Ảnh điện thoại: chưa có.
- Command/log bổ trợ: chưa có.

## Bug và retest

- Chưa xác định.
"@
  [IO.File]::WriteAllText((Join-Path $casesRoot "$($case.Id).md"), $content, $utf8)
}

$summary = @"
Commit de xuat: test(real-device): kiem thu toan bo NanoBio 15-07-2026

# Kiểm thử toàn bộ NanoBio trên điện thoại thật — 15/07/2026

## Trạng thái chiến dịch

- Kết luận: CHƯA HOÀN TẤT.
- Tổng case kế thừa và bắt buộc chạy lại: $($cases.Count).
- PASS: 0; FAIL: 0; BLOCKED: 0; PENDING: $($cases.Count).
- Không tái sử dụng ảnh hoặc trạng thái PASS từ chiến dịch cũ.

## Thiết bị và môi trường

- Thiết bị: Xiaomi 220333QPG (``12b304f9``).
- Android: 11/API 30.
- Độ phân giải vật lý: 720x1650.
- Supabase: cấu hình có trong ``assets/config/auth.env``; không ghi giá trị vào báo cáo.
- AI: BLOCKED ở preflight vì ``GEMINI_API_KEY`` là placeholder.

## Baseline kỹ thuật

- ``flutter analyze``: PASS — không có issue.
- Full test lần 1: FAIL — 679 PASS, 8 FAIL.
- Full test lần 2 để lọc failure: FAIL — 678 PASS, 9 FAIL; có thêm failure flaky ở idempotency key.
- Device ``flutter drive`` PRE-02: TIMEOUT sau 304 giây; app chưa được cài/mở nên không có ảnh và không được kết luận PASS.

## Nguyên tắc bằng chứng

- Mỗi case chỉ được đổi trạng thái sau khi có ảnh mới từ đúng điện thoại thật.
- Log/test tự động chỉ là bằng chứng bổ trợ.
- Bug chỉ được đánh dấu đã fix sau ảnh FAIL, patch, regression test, retest thiết bị và ảnh PASS.

## Ma trận

| Case | Hồ sơ | Trạng thái |
| --- | --- | --- |
$(($cases | ForEach-Object { "| $($_.Id) | [cases/$($_.Id).md](cases/$($_.Id).md) | PENDING |" }) -join "`n")
"@
[IO.File]::WriteAllText((Join-Path $root '001-test-full-project-real-device.md'), $summary, $utf8)
Write-Host "Created campaign with $($cases.Count) cases at $CampaignRoot"
