param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $ProjectRoot).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
  param([string]$Message)
  $script:failures.Add($Message) | Out-Null
}

function Read-Utf8Text {
  param([string]$Path)
  return [System.IO.File]::ReadAllText((Resolve-Path $Path).Path, $script:utf8NoBom)
}

function Get-ProjectRelativePath {
  param([string]$Path)
  $full = (Resolve-Path $Path).Path
  return $full.Substring($script:root.Length + 1).Replace("\", "/")
}

function Test-IsInsideProject {
  param([string]$Path)
  $full = [System.IO.Path]::GetFullPath($Path)
  return $full.StartsWith($script:root, [System.StringComparison]::OrdinalIgnoreCase)
}

$textExtensions = @(".md", ".ps1", ".json", ".yaml", ".yml")
$scanRoots = @(
  (Join-Path $root ".codex"),
  (Join-Path $root "docs\worklog")
) | Where-Object { Test-Path $_ }

$mojibakePattern = @(
  [regex]::Escape([string][char]0x00C3),
  [regex]::Escape([string][char]0x00C2),
  [regex]::Escape([string][char]0x00C4),
  [regex]::Escape([string][char]0x00C6),
  [regex]::Escape(([string][char]0x00E1) + ([string][char]0x00BB)),
  [regex]::Escape(([string][char]0x00E1) + ([string][char]0x00BA)),
  [regex]::Escape(([string][char]0x00E2) + ([string][char]0x20AC)),
  [regex]::Escape([string][char]0xFFFD)
) -join "|"

foreach ($scanRoot in $scanRoots) {
  Get-ChildItem -LiteralPath $scanRoot -Recurse -File |
    Where-Object { $textExtensions -contains $_.Extension.ToLowerInvariant() } |
    ForEach-Object {
      $text = Read-Utf8Text $_.FullName
      $matches = [regex]::Matches($text, $mojibakePattern)
      if ($matches.Count -gt 0) {
        $sample = ($matches | Select-Object -First 5 | ForEach-Object { $_.Value }) -join ", "
        Add-Failure "Mojibake suspected in $(Get-ProjectRelativePath $_.FullName): $sample"
      }
    }
}

$codexRoot = Join-Path $root ".codex"
$markdownFiles = Get-ChildItem -LiteralPath $codexRoot -Recurse -File -Filter "*.md"
$linkPattern = '(?<!\!)\[[^\]]+\]\((?<target>[^)]+)\)'

foreach ($file in $markdownFiles) {
  $text = Read-Utf8Text $file.FullName
  foreach ($match in [regex]::Matches($text, $linkPattern)) {
    $rawTarget = $match.Groups["target"].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($rawTarget)) { continue }
    if ($rawTarget -match '^(https?|mailto|app|file)://' -or $rawTarget.StartsWith("#")) { continue }

    $target = $rawTarget
    if ($target.StartsWith("<") -and $target.Contains(">")) {
      $target = $target.Substring(1, $target.IndexOf(">") - 1)
    } else {
      $target = ($target -split '\s+')[0]
    }
    if ($target.Contains("#")) {
      $target = $target.Substring(0, $target.IndexOf("#"))
    }
    if ([string]::IsNullOrWhiteSpace($target)) { continue }

    $candidate = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $target))
    if (-not (Test-IsInsideProject $candidate)) {
      Add-Failure "Markdown link escapes project: source=$(Get-ProjectRelativePath $file.FullName), link=$rawTarget, resolved=$candidate"
      continue
    }
    if (-not (Test-Path $candidate)) {
      Add-Failure "Broken Markdown link: source=$(Get-ProjectRelativePath $file.FullName), link=$rawTarget, expected=$candidate"
    }
  }
}

$canonicalTaskKeys = @(
  "coding",
  "bugfix",
  "fix-issues",
  "test",
  "find-issues",
  "create-issues",
  "create-todo",
  "docs-dd",
  "docs-context",
  "refactor-scaffold",
  "supabase-schema"
)
$allowedTaskDocs = @("README.md", "LEGACY_TASK_KEY_MAP.md") + ($canonicalTaskKeys | ForEach-Object { "$_.md" })
$taskSkillRoot = Join-Path $codexRoot "task-skills"
if (Test-Path $taskSkillRoot) {
  Get-ChildItem -LiteralPath $taskSkillRoot -File -Filter "*.md" | ForEach-Object {
    if ($allowedTaskDocs -notcontains $_.Name) {
      Add-Failure "Non-canonical task-skill file: $(Get-ProjectRelativePath $_.FullName)"
    }
  }
  foreach ($key in $canonicalTaskKeys) {
    $path = Join-Path $taskSkillRoot "$key.md"
    if (-not (Test-Path $path)) {
      Add-Failure "Missing canonical task-skill: .codex/task-skills/$key.md"
    }
  }
}

$openRisksPath = Join-Path $codexRoot "history\OPEN_RISKS.md"
if (Test-Path $openRisksPath) {
  $riskText = Read-Utf8Text $openRisksPath
  $riskMatches = [regex]::Matches($riskText, '(?ms)^## (?<id>NB-RISK-\d{3}) .+?(?=^## NB-RISK-\d{3}|\z)')
  if ($riskMatches.Count -eq 0) {
    Add-Failure "OPEN_RISKS.md has no structured NB-RISK entries."
  }
  foreach ($risk in $riskMatches) {
    $block = $risk.Value
    foreach ($field in @("Severity: P[0-3]", "Status: (Open|In Progress|Blocked|Needs Verification|Resolved)", "Updated: \d{4}-\d{2}-\d{2}", "Evidence:", "Impact:", "Proposed handling:", "Owner/scope:")) {
      if ($block -notmatch $field) {
        Add-Failure "OPEN_RISKS.md entry $($risk.Groups["id"].Value) missing field pattern: $field"
      }
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host "CODEX INTEGRITY VALIDATION FAILED"
  foreach ($failure in $failures) {
    Write-Host "- $failure"
  }
  exit 1
}

Write-Host "CODEX INTEGRITY VALIDATION PASSED"
