[CmdletBinding()]
param(
    [string]$EnvFile = ".env",
    [string]$OutputFile = ".dart_tool/nanobio_defines.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Resolve-ProjectPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $Path))
}

function Read-DotEnvFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Không tìm thấy file cấu hình: $Path"
    }

    $values = [ordered]@{}
    foreach ($rawLine in [System.IO.File]::ReadAllLines($Path)) {
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
        $value = $line.Substring($separatorIndex + 1).Trim()

        if ($value.Length -ge 2) {
            $first = $value[0]
            $last = $value[$value.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or
                ($first -eq "'" -and $last -eq "'")) {
                $value = $value.Substring(1, $value.Length - 2).Trim()
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $values[$key] = $value
        }
    }

    return $values
}

$allowedKeys = @(
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "AUTH_EMAIL_REDIRECT_URL",
    "AUTH_CONFIRM_EMAIL_REQUIRED",
    "ONBOARDING_AI_DEV_CHECK_ENABLED",
    "GEMINI_API_KEY",
    "GEMINI_BASE_URL",
    "GEMINI_MODEL",
    "GEMINI_PLAN_MODEL",
    "GEMINI_PLAN_FALLBACK_MODELS",
    "GEMINI_FALLBACK_MODELS",
    "GEMINI_PLAN_OVERFLOW_MODELS",
    "GEMINI_CHAT_MODEL",
    "GEMINI_CHAT_FALLBACK_MODELS"
)

$resolvedEnvFile = Resolve-ProjectPath $EnvFile
$resolvedOutputFile = Resolve-ProjectPath $OutputFile
$envValues = Read-DotEnvFile $resolvedEnvFile

$apiKey = [string]$envValues["GEMINI_API_KEY"]
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "GEMINI_API_KEY đang thiếu hoặc rỗng trong $resolvedEnvFile"
}
if ($apiKey.Trim().Length -lt 20) {
    throw "GEMINI_API_KEY có định dạng quá ngắn. Hãy tạo lại khóa trong Google AI Studio."
}

if ($envValues.Contains("GEMINI_BASE_URL") -and
    -not [string]::IsNullOrWhiteSpace([string]$envValues["GEMINI_BASE_URL"])) {
    $baseUri = $null
    if (-not [System.Uri]::TryCreate(
        ([string]$envValues["GEMINI_BASE_URL"]).Trim(),
        [System.UriKind]::Absolute,
        [ref]$baseUri
    ) -or $baseUri.Scheme -ne "https") {
        throw "GEMINI_BASE_URL phải là URL HTTPS hợp lệ."
    }
}

$defines = [ordered]@{}
foreach ($key in $allowedKeys) {
    if (-not $envValues.Contains($key)) {
        continue
    }

    $value = ([string]$envValues[$key]).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        continue
    }

    $defines[$key] = $value
}

$outputDirectory = Split-Path -Parent $resolvedOutputFile
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$json = $defines | ConvertTo-Json -Compress
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($resolvedOutputFile, $json, $utf8WithoutBom)

Write-Host "Đã tạo cấu hình runtime an toàn tại $resolvedOutputFile"
Write-Host "Đã nạp $($defines.Count) biến; giá trị bí mật không được in ra terminal."
