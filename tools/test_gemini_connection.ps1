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

$supabaseUrl = [string]$values["SUPABASE_URL"]
$anonKey = [string]$values["SUPABASE_ANON_KEY"]
if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or
    [string]::IsNullOrWhiteSpace($anonKey)) {
    throw "SUPABASE_URL và SUPABASE_ANON_KEY là bắt buộc để kiểm tra AI backend."
}

$model = [string]$values["GEMINI_MODEL"]
if ([string]::IsNullOrWhiteSpace($model)) {
    $model = "gemini-2.5-flash"
}

$headers = @{
    "Authorization" = "Bearer $anonKey"
    "apikey" = $anonKey
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$body = @{
    model = $model
    contents = @(
        @{
            role = "user"
            parts = @(@{ text = "Hãy trả lời đúng một câu tiếng Việt chào người dùng." })
        }
    )
    generation_config = @{
        candidateCount = 1
        maxOutputTokens = 80
        temperature = 0.2
        topP = 0.8
    }
} | ConvertTo-Json -Depth 8 -Compress

$endpoint = "$($supabaseUrl.TrimEnd('/'))/functions/v1/nabi-ai-generate"
try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $body -TimeoutSec 30
    $text = [string]$response.text
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "AI backend trả về response rỗng."
    }

    Write-Host "Kết nối AI backend thành công."
    Write-Host "Độ dài phản hồi: $($text.Trim().Length) ký tự."
    exit 0
} catch {
    $statusCode = $null
    try {
        $statusCode = [int]$_.Exception.Response.StatusCode
    } catch {
        $statusCode = $null
    }
    throw "AI backend chưa sẵn sàng (HTTP $statusCode). Lỗi chi tiết không được in để tránh lộ dữ liệu."
}
