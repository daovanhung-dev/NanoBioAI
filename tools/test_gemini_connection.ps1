[CmdletBinding()]
param(
    [string]$EnvFile = ".env"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile
} else {
    Join-Path $ProjectRoot $EnvFile
}
if (-not (Test-Path -LiteralPath $EnvPath -PathType Leaf)) {
    throw "Không tìm thấy file cấu hình: $EnvPath"
}

$values = @{}
foreach ($rawLine in [System.IO.File]::ReadAllLines($EnvPath)) {
    $line = $rawLine.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        continue
    }
    if ($line.StartsWith("export ")) {
        $line = $line.Substring(7).TrimStart()
    }
    $separatorIndex = $line.IndexOf("=")
    if ($separatorIndex -le 0) {
        continue
    }
    $key = $line.Substring(0, $separatorIndex).Trim().TrimStart([char]0xFEFF)
    $value = $line.Substring($separatorIndex + 1).Trim().Trim('"').Trim("'")
    $values[$key] = $value
}

$apiBaseUrl = [string]$values["API_BASE_URL"]
$accessToken = [string]$env:NANOBIO_API_ACCESS_TOKEN
if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) {
    throw "API_BASE_URL là bắt buộc để kiểm tra AI backend."
}
if ([string]::IsNullOrWhiteSpace($accessToken)) {
    throw "Hãy đặt NANOBIO_API_ACCESS_TOKEN trong môi trường chạy để xác thực với backend."
}

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$body = @{
    messages = @(@{ role = "user"; content = "Hãy trả lời đúng một câu tiếng Việt chào người dùng." })
    max_output_tokens = 128
    temperature = 0.2
} | ConvertTo-Json -Depth 8 -Compress

$endpoint = "$($apiBaseUrl.TrimEnd('/'))/api/v1/ai/generate"
try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $body -TimeoutSec 30
    $data = if ($response.data) { $response.data } else { $response }
    $text = [string]$data.text
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "AI backend trả về response rỗng."
    }

    Write-Host "Kết nối AI server thành công."
    Write-Host "Độ dài phản hồi: $($text.Trim().Length) ký tự."
    exit 0
} catch {
    $statusCode = $null
    try {
        $statusCode = [int]$_.Exception.Response.StatusCode
    } catch {
        $statusCode = $null
    }
    throw "AI server chưa sẵn sàng (HTTP $statusCode). Lỗi chi tiết không được in để tránh lộ dữ liệu."
}
