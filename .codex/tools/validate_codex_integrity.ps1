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

function Test-ShouldSkipBacktickPath {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
  if ($Value -match '[<>\*\?\{\}\[\]\|]') { return $true }
  if ($Value -match '\s') { return $true }
  if ($Value -match '^(https?|mailto|app|file)://') { return $true }
  if ($Value -match '^[A-Z_][A-Z0-9_]*$') { return $true }
  return $false
}

function Test-IsConcreteProjectPath {
  param([string]$Value)
  if (Test-ShouldSkipBacktickPath $Value) { return $false }
  $normalized = $Value.Trim().Trim([char[]]@([char]0x60, [char]0x22, [char]0x27))
  if ($normalized.StartsWith("./")) { $normalized = $normalized.Substring(2) }
  if ($normalized -match '^(AGENTS\.md|README\.md|pubspec\.yaml|analysis_options\.yaml)$') { return $true }
  if ($normalized -match '^(\.codex|\.agents|docs|lib|test|assets|android|ios|linux|macos|web|windows)/') { return $true }
  return $false
}

function Resolve-ProjectPathFromBacktick {
  param([string]$Value)
  $normalized = $Value.Trim().Trim([char[]]@([char]0x60, [char]0x22, [char]0x27))
  if ($normalized.StartsWith("./")) { $normalized = $normalized.Substring(2) }
  $normalized = $normalized.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
  return [System.IO.Path]::GetFullPath((Join-Path $script:root $normalized))
}

$textExtensions = @(".md", ".ps1", ".json", ".yaml", ".yml")
$scanRoots = @(
  (Join-Path $root ".codex"),
  (Join-Path $root ".agents"),
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
$markdownFiles = @()
if (Test-Path $codexRoot) {
  $markdownFiles += Get-ChildItem -LiteralPath $codexRoot -Recurse -File -Filter "*.md"
}
$agentsRoot = Join-Path $root ".agents"
if (Test-Path $agentsRoot) {
  $markdownFiles += Get-ChildItem -LiteralPath $agentsRoot -Recurse -File -Filter "*.md"
}
$rootAgentsPath = Join-Path $root "AGENTS.md"
if (Test-Path $rootAgentsPath) {
  $markdownFiles += Get-Item -LiteralPath $rootAgentsPath
}
$linkPattern = '(?<!\!)\[[^\]]+\]\((?<target>[^)]+)\)'
$backtickPattern = '`(?<value>[^`\r\n]+)`'

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

  if ((Get-ProjectRelativePath $file.FullName) -ne ".codex/history/RISK_HISTORY.md") {
    foreach ($match in [regex]::Matches($text, $backtickPattern)) {
      $rawValue = $match.Groups["value"].Value.Trim()
      if (-not (Test-IsConcreteProjectPath $rawValue)) { continue }
      $candidate = Resolve-ProjectPathFromBacktick $rawValue
      if (-not (Test-IsInsideProject $candidate)) {
        Add-Failure "Backticked path escapes project: source=$(Get-ProjectRelativePath $file.FullName), path=$rawValue, resolved=$candidate"
        continue
      }
      if (-not (Test-Path $candidate)) {
        Add-Failure "Stale backticked path: source=$(Get-ProjectRelativePath $file.FullName), path=$rawValue, expected=$candidate"
      }
    }
  }
}

if (-not (Test-Path $rootAgentsPath)) {
  Add-Failure "Missing root AGENTS.md bridge."
} else {
  $rootAgentsText = Read-Utf8Text $rootAgentsPath
  if ($rootAgentsText -notmatch [regex]::Escape(".codex/AGENTS.md")) {
    Add-Failure "Root AGENTS.md does not bridge to .codex/AGENTS.md."
  }
}

$skillBridgePath = Join-Path $root ".agents\skills\nanobio-project-agent\SKILL.md"
if (-not (Test-Path $skillBridgePath)) {
  Add-Failure "Missing .agents skill bridge: .agents/skills/nanobio-project-agent/SKILL.md"
} else {
  $skillBridgeText = Read-Utf8Text $skillBridgePath
  if ($skillBridgeText -notmatch [regex]::Escape(".codex/skills/nanobio-project-agent/SKILL.md")) {
    Add-Failure ".agents skill bridge does not point to .codex/skills/nanobio-project-agent/SKILL.md."
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
