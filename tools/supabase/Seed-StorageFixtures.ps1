<#
.SYNOPSIS
Seeds private Storage proof objects for the local/sandbox comprehensive fixture.

.DESCRIPTION
Uses the Supabase Auth, REST/RPC, and Storage HTTP APIs only. It never opens a
database connection and never writes to storage.objects directly. The runner
is one-shot after a destructive local/sandbox rebuild because it creates
immutable schedule evidence. It removes only the dedicated wellness fixture
prefix and payout objects below the selected fixture conversion prefix.

The target must be localhost/loopback, a .local host, or a hostname explicitly
labelled sandbox. Any other host, including staging, requires -AllowNonLocal.
Supply the
local-only fixture password interactively, or as a SecureString parameter; no
credentials are stored in this script.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools/supabase/Seed-StorageFixtures.ps1

.EXAMPLE
$fixturePassword = Read-Host 'Fixture password' -AsSecureString
& .\tools\supabase\Seed-StorageFixtures.ps1 `
  -FixturePassword $fixturePassword -MarkSaleConversionPaid
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$WellnessFixtureEmail = 'dev.fixture.wellness@nanobio.local',
  [string]$SaleFixtureEmail = 'dev.fixture.sale.active@nanobio.local',
  [string]$AdminFixtureEmail = 'dev.admin@nanobio.local',
  [securestring]$FixturePassword,
  [switch]$MarkSaleConversionPaid,
  [switch]$AllowNonLocal
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RequiredEnvironmentValue {
  param([Parameter(Mandatory = $true)][string]$Name)

  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing required environment variable: $Name"
  }
  return $value.Trim()
}

function Get-PlainTextSecureString {
  param([Parameter(Mandatory = $true)][securestring]$Value)

  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}

function Test-AllowedTargetHost {
  param(
    [Parameter(Mandatory = $true)][uri]$Uri,
    [switch]$AllowNonLocal
  )

  if ($Uri.Scheme -notin @('http', 'https')) {
    throw 'NANOBIO_SUPABASE_URL must use http or https.'
  }
  if (-not [string]::IsNullOrEmpty($Uri.Query) -or
      ($Uri.AbsolutePath -ne '/' -and $Uri.AbsolutePath -ne '')) {
    throw 'NANOBIO_SUPABASE_URL must be a base URL without a path or query.'
  }

  $hostName = $Uri.DnsSafeHost.ToLowerInvariant()
  $isLoopback = $hostName -in @('localhost', '127.0.0.1', '::1')
  $isLocalDomain = $hostName.EndsWith('.local')
  $isNamedSandbox = $hostName -match '(^|[.-])sandbox([.-]|$)'

  if (-not ($isLoopback -or $isLocalDomain -or $isNamedSandbox) -and
      -not $AllowNonLocal) {
    throw (
      'Refusing a non-local/non-sandbox Supabase host. ' +
      'Use -AllowNonLocal only after verifying this is a disposable environment.'
    )
  }
}

function Get-RequestFailureMessage {
  param(
    [Parameter(Mandatory = $true)]$ErrorRecord,
    [Parameter(Mandatory = $true)][string]$Operation
  )

  $statusCode = $null
  $responseProperty = $ErrorRecord.Exception.PSObject.Properties['Response']
  if ($null -ne $responseProperty -and $null -ne $responseProperty.Value) {
    try {
      $statusCode = [int]$responseProperty.Value.StatusCode
    }
    catch {
      $statusCode = $null
    }
  }

  if ($null -ne $statusCode) {
    return "$Operation failed (HTTP $statusCode)."
  }
  return "$Operation failed. Check the local/sandbox endpoint and fixture setup."
}

function Invoke-JsonRequest {
  param(
    [Parameter(Mandatory = $true)][ValidateSet('Get', 'Post', 'Patch', 'Delete')][string]$Method,
    [Parameter(Mandatory = $true)][string]$Uri,
    [Parameter(Mandatory = $true)][hashtable]$Headers,
    [object]$Body,
    [Parameter(Mandatory = $true)][string]$Operation
  )

  $request = @{
    Method = $Method
    Uri = $Uri
    Headers = $Headers
    ErrorAction = 'Stop'
  }
  if ($PSBoundParameters.ContainsKey('Body')) {
    $request['Body'] = $Body | ConvertTo-Json -Depth 20 -Compress
    $request['ContentType'] = 'application/json'
  }

  try {
    return Invoke-RestMethod @request
  }
  catch {
    throw (Get-RequestFailureMessage -ErrorRecord $_ -Operation $Operation)
  }
}

function Escape-StoragePath {
  param([Parameter(Mandatory = $true)][string]$Path)

  return ([uri]::EscapeDataString($Path)).Replace('%2F', '/')
}

function Assert-FixtureUuid {
  param(
    [Parameter(Mandatory = $true)][string]$Value,
    [Parameter(Mandatory = $true)][string]$Label
  )

  $parsed = [guid]::Empty
  if (-not [guid]::TryParse($Value, [ref]$parsed)) {
    throw "$Label must be a UUID in the local/sandbox fixture."
  }
  return $parsed.ToString()
}

function New-ApiHeaders {
  param(
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$ApiKey
  )

  return @{
    apikey = $ApiKey
    Authorization = "Bearer $AccessToken"
    Accept = 'application/json'
  }
}

function Sign-InFixture {
  param(
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][string]$Password,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  $response = Invoke-JsonRequest `
    -Method Post `
    -Uri "$BaseUrl/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $AnonKey; Accept = 'application/json' } `
    -Body @{ email = $Email; password = $Password } `
    -Operation "Fixture sign-in for $Email"

  $token = $response.access_token.ToString()
  $userId = $response.user.id.ToString()
  if ([string]::IsNullOrWhiteSpace($token) -or [string]::IsNullOrWhiteSpace($userId)) {
    throw "Fixture sign-in for $Email returned an incomplete session."
  }
  $userId = Assert-FixtureUuid -Value $userId -Label "Fixture user ID for $Email"

  return [pscustomobject]@{
    Email = $Email
    AccessToken = $token
    UserId = $userId
  }
}

function Invoke-SupabaseRpc {
  param(
    [Parameter(Mandatory = $true)][string]$FunctionName,
    [Parameter(Mandatory = $true)][hashtable]$Parameters,
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  return Invoke-JsonRequest `
    -Method Post `
    -Uri "$BaseUrl/rest/v1/rpc/$FunctionName" `
    -Headers (New-ApiHeaders -AccessToken $AccessToken -ApiKey $AnonKey) `
    -Body $Parameters `
    -Operation "RPC $FunctionName"
}

function Get-StorageObjects {
  param(
    [Parameter(Mandatory = $true)][string]$Bucket,
    [Parameter(Mandatory = $true)][string]$Prefix,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][hashtable]$ServiceHeaders
  )

  $all = @()
  $offset = 0
  do {
    $page = Invoke-JsonRequest `
      -Method Post `
      -Uri "$BaseUrl/storage/v1/object/list/$Bucket" `
      -Headers $ServiceHeaders `
      -Body @{
        prefix = $Prefix
        limit = 1000
        offset = $offset
        sortBy = @{ column = 'name'; order = 'asc' }
      } `
      -Operation "List fixture objects in $Bucket"
    $items = @($page | Where-Object { $null -ne $_ })
    $all += $items
    $offset += $items.Count
  } while ($items.Count -eq 1000)

  return $all
}

function Remove-StorageObject {
  param(
    [Parameter(Mandatory = $true)][string]$Bucket,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][hashtable]$ServiceHeaders
  )

  if (-not $PSCmdlet.ShouldProcess("$Bucket/$Path", 'Remove fixture Storage object')) {
    return
  }

  $uri = "$BaseUrl/storage/v1/object/$Bucket/$(Escape-StoragePath -Path $Path)"
  Invoke-JsonRequest `
    -Method Delete `
    -Uri $uri `
    -Headers $ServiceHeaders `
    -Operation "Remove fixture object $Path" | Out-Null
}

function Remove-AbandonedScheduleFixtureObjects {
  param(
    [Parameter(Mandatory = $true)]$WellnessSession,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey,
    [Parameter(Mandatory = $true)][hashtable]$ServiceHeaders
  )

  $prefix = "$($WellnessSession.UserId)/"
  foreach ($object in Get-StorageObjects `
    -Bucket 'schedule-completion-proofs' `
    -Prefix $prefix `
    -BaseUrl $BaseUrl `
    -ServiceHeaders $ServiceHeaders) {
    $path = $object.name.ToString()
    if ($path.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
      Remove-StorageObject `
        -Bucket 'schedule-completion-proofs' `
        -Path $path `
        -BaseUrl $BaseUrl `
        -ServiceHeaders $ServiceHeaders
    }
  }
}

function Upload-StorageJpeg {
  param(
    [Parameter(Mandatory = $true)][string]$Bucket,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][byte[]]$Bytes,
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  $uri = "$BaseUrl/storage/v1/object/$Bucket/$(Escape-StoragePath -Path $Path)"
  $headers = New-ApiHeaders -AccessToken $AccessToken -ApiKey $AnonKey
  $headers['x-upsert'] = 'false'

  try {
    Invoke-RestMethod `
      -Method Post `
      -Uri $uri `
      -Headers $headers `
      -ContentType 'image/jpeg' `
      -Body $Bytes `
      -ErrorAction Stop | Out-Null
  }
  catch {
    throw (Get-RequestFailureMessage -ErrorRecord $_ -Operation "Upload $Bucket/$Path")
  }
}

function Confirm-StorageJpeg {
  param(
    [Parameter(Mandatory = $true)][string]$Bucket,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][int]$ExpectedLength,
    [Parameter(Mandatory = $true)][string]$AccessToken,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  $temporaryPath = [IO.Path]::Combine(
    [IO.Path]::GetTempPath(),
    "nanobio-storage-fixture-$([guid]::NewGuid().ToString('N')).jpg"
  )
  $uri = "$BaseUrl/storage/v1/object/authenticated/$Bucket/$(Escape-StoragePath -Path $Path)"

  try {
    Invoke-WebRequest `
      -Method Get `
      -Uri $uri `
      -Headers (New-ApiHeaders -AccessToken $AccessToken -ApiKey $AnonKey) `
      -OutFile $temporaryPath `
      -ErrorAction Stop | Out-Null
    if ((Get-Item -LiteralPath $temporaryPath).Length -ne $ExpectedLength) {
      throw "Downloaded proof length did not match the uploaded fixture for $Bucket/$Path."
    }
  }
  catch {
    if ($_.Exception.Message -like 'Downloaded proof length*') {
      throw
    }
    throw (Get-RequestFailureMessage -ErrorRecord $_ -Operation "Download $Bucket/$Path")
  }
  finally {
    if (Test-Path -LiteralPath $temporaryPath) {
      Remove-Item -LiteralPath $temporaryPath -Force
    }
  }
}

function Get-OpenScheduleEligibilities {
  param(
    [Parameter(Mandatory = $true)]$WellnessSession,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  $rows = Invoke-JsonRequest `
    -Method Get `
    -Uri "$BaseUrl/rest/v1/schedule_reward_eligibilities?select=schedule_item_id,status,window_start,window_end&status=eq.eligible&order=window_start.asc" `
    -Headers (New-ApiHeaders -AccessToken $WellnessSession.AccessToken -ApiKey $AnonKey) `
    -Operation 'Read fixture schedule eligibilities'
  $now = [datetimeoffset]::UtcNow

  $eligible = @($rows | Where-Object { $null -ne $_ } | Where-Object {
    try {
      $start = [datetimeoffset]::Parse($_.window_start.ToString())
      $end = [datetimeoffset]::Parse($_.window_end.ToString())
      return $start -le $now -and $end -gt $now.AddMinutes(2)
    }
    catch {
      return $false
    }
  } | Select-Object -First 2)

  if ($eligible.Count -ne 2) {
    throw (
      'Two open schedule reward eligibilities were not found for the wellness fixture. ' +
      'Apply the demo profile and rebuild the comprehensive seed before running this script.'
    )
  }
  return $eligible
}

function Complete-ScheduleFixtureEligibility {
  param(
    [Parameter(Mandatory = $true)]$Eligibility,
    [Parameter(Mandatory = $true)]$WellnessSession,
    [Parameter(Mandatory = $true)][string]$IdempotencySuffix,
    [Parameter(Mandatory = $true)][byte[]]$JpegBytes,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  $scheduleItemId = Assert-FixtureUuid `
    -Value $Eligibility.schedule_item_id.ToString() `
    -Label 'Schedule reward item ID'
  $scheduleBegin = Invoke-SupabaseRpc `
    -FunctionName 'begin_my_schedule_completion' `
    -Parameters @{
      p_schedule_item_id = $scheduleItemId
      p_idempotency_key = "storage-fixture-begin-$IdempotencySuffix-$([guid]::NewGuid().ToString('N'))"
    } `
    -AccessToken $WellnessSession.AccessToken `
    -BaseUrl $BaseUrl `
    -AnonKey $AnonKey
  $schedulePath = $scheduleBegin.storage_path.ToString()
  $attemptId = $scheduleBegin.attempt_id.ToString()
  if ([string]::IsNullOrWhiteSpace($schedulePath) -or [string]::IsNullOrWhiteSpace($attemptId)) {
    throw 'begin_my_schedule_completion did not return the server-issued proof path.'
  }
  $attemptId = Assert-FixtureUuid -Value $attemptId -Label 'Schedule completion attempt ID'
  $expectedSchedulePrefix = "$($WellnessSession.UserId)/"
  if (-not $schedulePath.StartsWith($expectedSchedulePrefix, [System.StringComparison]::Ordinal) -or
      -not $schedulePath.EndsWith('.jpg', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'begin_my_schedule_completion returned an unsafe fixture proof path.'
  }

  Upload-StorageJpeg `
    -Bucket 'schedule-completion-proofs' `
    -Path $schedulePath `
    -Bytes $JpegBytes `
    -AccessToken $WellnessSession.AccessToken `
    -BaseUrl $BaseUrl `
    -AnonKey $AnonKey
  Confirm-StorageJpeg `
    -Bucket 'schedule-completion-proofs' `
    -Path $schedulePath `
    -ExpectedLength $JpegBytes.Length `
    -AccessToken $WellnessSession.AccessToken `
    -BaseUrl $BaseUrl `
    -AnonKey $AnonKey
  Invoke-SupabaseRpc `
    -FunctionName 'finalize_my_schedule_completion' `
    -Parameters @{
      p_attempt_id = $attemptId
      p_storage_path = $schedulePath
      p_idempotency_key = "storage-fixture-finalize-$IdempotencySuffix-$([guid]::NewGuid().ToString('N'))"
    } `
    -AccessToken $WellnessSession.AccessToken `
    -BaseUrl $BaseUrl `
    -AnonKey $AnonKey | Out-Null

  return [pscustomobject]@{
    ScheduleItemId = $scheduleItemId
    AttemptId = $attemptId
    StoragePath = $schedulePath
  }
}

function Assert-FreshStorageFixtureRun {
  param(
    [Parameter(Mandatory = $true)]$WellnessSession,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$AnonKey
  )

  $headers = New-ApiHeaders `
    -AccessToken $WellnessSession.AccessToken `
    -ApiKey $AnonKey
  $attempts = Invoke-JsonRequest `
    -Method Get `
    -Uri "$BaseUrl/rest/v1/schedule_completion_attempts?select=id,status&limit=1" `
    -Headers $headers `
    -Operation 'Check existing wellness fixture attempts'
  $proofs = Invoke-JsonRequest `
    -Method Get `
    -Uri "$BaseUrl/rest/v1/schedule_completion_proofs?select=id,status&limit=1" `
    -Headers $headers `
    -Operation 'Check existing wellness fixture proofs'

  if (@($attempts | Where-Object { $null -ne $_ }).Count -gt 0 -or
      @($proofs | Where-Object { $null -ne $_ }).Count -gt 0) {
    throw (
      'Storage fixture runner is one-shot after a destructive rebuild. ' +
      'Run config.sql and the opt-in demo profile again before retrying.'
    )
  }
}

$baseUrl = Get-RequiredEnvironmentValue -Name 'NANOBIO_SUPABASE_URL'
$anonKey = Get-RequiredEnvironmentValue -Name 'NANOBIO_SUPABASE_ANON_KEY'
$serviceRoleKey = Get-RequiredEnvironmentValue -Name 'NANOBIO_SUPABASE_SERVICE_ROLE_KEY'

[uri]$supabaseUri = $baseUrl
Test-AllowedTargetHost -Uri $supabaseUri -AllowNonLocal:$AllowNonLocal
$baseUrl = $baseUrl.TrimEnd('/')

if ($null -eq $FixturePassword) {
  $FixturePassword = Read-Host 'Local/sandbox fixture password' -AsSecureString
}
$fixturePasswordText = Get-PlainTextSecureString -Value $FixturePassword
$serviceHeaders = New-ApiHeaders -AccessToken $serviceRoleKey -ApiKey $serviceRoleKey

# A tiny valid JPEG fixture. It contains no person or production data.
$jpegBytes = [Convert]::FromBase64String(
  '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD9AKKKKAP/2Q=='
)

try {
  $wellnessSession = Sign-InFixture `
    -Email $WellnessFixtureEmail `
    -Password $fixturePasswordText `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  Assert-FreshStorageFixtureRun `
    -WellnessSession $wellnessSession `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  Remove-AbandonedScheduleFixtureObjects `
    -WellnessSession $wellnessSession `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey `
    -ServiceHeaders $serviceHeaders

  $eligibilities = Get-OpenScheduleEligibilities `
    -WellnessSession $wellnessSession `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  $activeScheduleProof = Complete-ScheduleFixtureEligibility `
    -Eligibility $eligibilities[0] `
    -WellnessSession $wellnessSession `
    -IdempotencySuffix 'active' `
    -JpegBytes $jpegBytes `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  $reversedScheduleProof = Complete-ScheduleFixtureEligibility `
    -Eligibility $eligibilities[1] `
    -WellnessSession $wellnessSession `
    -IdempotencySuffix 'reversed' `
    -JpegBytes $jpegBytes `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  Invoke-SupabaseRpc `
    -FunctionName 'undo_my_schedule_completion' `
    -Parameters @{
      p_schedule_item_id = $reversedScheduleProof.ScheduleItemId
      p_idempotency_key = "storage-fixture-undo-$([guid]::NewGuid().ToString('N'))"
    } `
    -AccessToken $wellnessSession.AccessToken `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey | Out-Null

  $saleSession = Sign-InFixture `
    -Email $SaleFixtureEmail `
    -Password $fixturePasswordText `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  $saleConversions = Invoke-SupabaseRpc `
    -FunctionName 'get_my_sale_conversions' `
    -Parameters @{} `
    -AccessToken $saleSession.AccessToken `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  # Keep one approved conversion in the dataset even when the optional paid
  # action below is exercised. The runner must use its dedicated proof target.
  $fixturePayoutConversionId = '66000000-0000-4000-8000-000000000003'
  $approvedConversion = @($saleConversions | Where-Object {
    $null -ne $_ -and
      $_.status.ToString() -eq 'approved' -and
      $_.id.ToString() -eq $fixturePayoutConversionId
  } | Select-Object -First 1)
  if ($approvedConversion.Count -ne 1) {
    throw (
      "The dedicated approved Sale conversion $fixturePayoutConversionId was not found. " +
      'The comprehensive seed must provide it before this Storage smoke can run.'
    )
  }
  $conversionId = Assert-FixtureUuid `
    -Value $approvedConversion[0].id.ToString() `
    -Label 'Approved Sale conversion ID'

  $adminSession = Sign-InFixture `
    -Email $AdminFixtureEmail `
    -Password $fixturePasswordText `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  $salePrefix = "sale-point-conversions/$conversionId/"
  foreach ($object in Get-StorageObjects `
    -Bucket 'sale-payout-proofs' `
    -Prefix $salePrefix `
    -BaseUrl $baseUrl `
    -ServiceHeaders $serviceHeaders) {
    $name = $object.name.ToString()
    if ($name.StartsWith($salePrefix, [System.StringComparison]::Ordinal)) {
      Remove-StorageObject `
        -Bucket 'sale-payout-proofs' `
        -Path $name `
        -BaseUrl $baseUrl `
        -ServiceHeaders $serviceHeaders
    }
  }

  $timestamp = [datetimeoffset]::UtcNow.ToUnixTimeMilliseconds()
  $saleProofPath = "${salePrefix}${timestamp}-fixture-payout-proof.jpg"
  Upload-StorageJpeg `
    -Bucket 'sale-payout-proofs' `
    -Path $saleProofPath `
    -Bytes $jpegBytes `
    -AccessToken $adminSession.AccessToken `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey
  Confirm-StorageJpeg `
    -Bucket 'sale-payout-proofs' `
    -Path $saleProofPath `
    -ExpectedLength $jpegBytes.Length `
    -AccessToken $adminSession.AccessToken `
    -BaseUrl $baseUrl `
    -AnonKey $anonKey

  if ($MarkSaleConversionPaid) {
    Invoke-SupabaseRpc `
      -FunctionName 'admin_review_sale_point_conversion' `
      -Parameters @{
        p_conversion_id = $conversionId
        p_decision = 'mark_paid'
        p_reason = 'Fixture payout proof confirmed in local/sandbox.'
        p_idempotency_key = "storage-fixture-sale-paid-$([guid]::NewGuid().ToString('N'))"
        p_payment_proof_path = $saleProofPath
      } `
      -AccessToken $adminSession.AccessToken `
      -BaseUrl $baseUrl `
      -AnonKey $anonKey | Out-Null
  }

  Write-Host "Active schedule proof finalized: $($activeScheduleProof.StoragePath)"
  Write-Host "Reversed schedule proof finalized and undone: $($reversedScheduleProof.StoragePath)"
  Write-Host "Sale payout proof uploaded: $saleProofPath"
  if ($MarkSaleConversionPaid) {
    Write-Host 'The fixture Sale conversion was marked paid with the uploaded proof.'
  }
}
finally {
  $fixturePasswordText = $null
}
