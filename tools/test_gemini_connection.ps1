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

$apiKey = [string]$values["GEMINI_API_KEY"]
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "GEMINI_API_KEY đang thiếu hoặc rỗng."
}

$baseUrl = [string]$values["GEMINI_BASE_URL"]
if ([string]::IsNullOrWhiteSpace($baseUrl)) {
    $baseUrl = "https://generativelanguage.googleapis.com/v1beta"
}
$baseUrl = $baseUrl.TrimEnd('/')

$models = New-Object System.Collections.Generic.List[string]
foreach ($candidate in @(
    [string]$values["GEMINI_CHAT_MODEL"],
    [string]$values["GEMINI_MODEL"],
    "gemini-3.5-flash",
    "gemini-3.1-flash-lite"
)) {
    if (-not [string]::IsNullOrWhiteSpace($candidate) -and
        -not $models.Contains($candidate.Trim())) {
        $models.Add($candidate.Trim())
    }
}

$headers = @{
    "x-goog-api-key" = $apiKey
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$body = @{
    contents = @(
        @{
            role = "user"
            parts = @(@{ text = "Hãy trả lời đúng một câu tiếng Việt chào người dùng." })
        }
    )
    generationConfig = @{
        candidateCount = 1
        maxOutputTokens = 80
        temperature = 0.2
        topP = 0.8
    }
} | ConvertTo-Json -Depth 8 -Compress

$lastError = $null
foreach ($model in $models) {
    $endpoint = "$baseUrl/models/$([System.Uri]::EscapeDataString($model)):generateContent"
    try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri $endpoint `
            -Headers $headers `
            -Body $body `
            -TimeoutSec 30

        $text = [string]$response.candidates[0].content.parts[0].text
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "Gemini trả về response rỗng."
        }

        Write-Host "Kết nối Gemini thành công với model: $model"
        Write-Host "Độ dài phản hồi: $($text.Trim().Length) ký tự."
        exit 0
    } catch {
        $lastError = $_
        $statusCode = $null
        try {
            $statusCode = [int]$_.Exception.Response.StatusCode
        } catch {
            $statusCode = $null
        }

        if ($statusCode -eq 401 -or $statusCode -eq 403) {
            throw "Gemini từ chối API key ($statusCode). Hãy tạo/cấp quyền lại khóa trong Google AI Studio."
        }

        Write-Warning "Model $model chưa dùng được; đang thử model tiếp theo."
    }
}

throw "Không model Gemini nào kết nối thành công. Lỗi cuối: $($lastError.Exception.Message)"
