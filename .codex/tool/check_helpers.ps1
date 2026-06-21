$script:CodexSkippedSteps = New-Object System.Collections.Generic.List[string]

function Write-CodexStep {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message"
}

function Add-CodexSkippedStep {
  param(
    [string]$Step,
    [string]$Reason
  )
  $message = "SKIPPED: $Step - $Reason"
  $script:CodexSkippedSteps.Add($message) | Out-Null
  Write-Host $message
}

function Invoke-NativeCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Step,
    [Parameter(Mandatory = $true)][string]$Command,
    [string[]]$Arguments = @()
  )

  Write-CodexStep $Step
  Write-Host ("Command: {0} {1}" -f $Command, ($Arguments -join " "))

  $stdoutPath = [System.IO.Path]::GetTempFileName()
  $stderrPath = [System.IO.Path]::GetTempFileName()
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    & $Command @Arguments 1> $stdoutPath 2> $stderrPath
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference

    $stdout = if (Test-Path $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw -Encoding UTF8 } else { "" }
    $stderr = if (Test-Path $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8 } else { "" }

    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
      Write-Host $stdout.TrimEnd()
    }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
      Write-Host $stderr.TrimEnd()
    }

    if ($exitCode -ne 0) {
      $details = if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        $stderr.Trim()
      } elseif (-not [string]::IsNullOrWhiteSpace($stdout)) {
        $stdout.Trim()
      } else {
        "No stdout/stderr captured."
      }
      throw "FAILED: $Step`nCommand: $Command $($Arguments -join ' ')`nExit code: $exitCode`nOutput:`n$details"
    }
  }
  catch {
    $ErrorActionPreference = $previousErrorActionPreference
    if ($_.Exception.Message -like "FAILED:*") {
      throw
    }
    throw "FAILED: $Step`nCommand: $Command $($Arguments -join ' ')`nCould not start or complete command.`n$($_.Exception.Message)"
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
  }
}

function Complete-CodexCheck {
  param([string]$Name)
  if ($script:CodexSkippedSteps.Count -gt 0) {
    Write-Host ""
    Write-Host "$Name COMPLETED WITH SKIPPED STEPS"
    foreach ($step in $script:CodexSkippedSteps) {
      Write-Host $step
    }
  } else {
    Write-Host ""
    Write-Host "$Name PASSED"
  }
}
