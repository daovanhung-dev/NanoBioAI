param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $ProjectRoot).Path
$worklogRoot = Join-Path $root "docs\worklog"
$historyRoot = Join-Path $root ".codex\history"
$taskSkillRoot = Join-Path $root ".codex\task-skills"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
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

if (-not (Test-Path $worklogRoot)) {
  throw "docs/worklog not found"
}

New-Item -ItemType Directory -Force -Path $historyRoot | Out-Null
New-Item -ItemType Directory -Force -Path $taskSkillRoot | Out-Null

function Read-Utf8Text {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.File]::ReadAllText((Resolve-Path $Path).Path, $script:utf8NoBom)
}

function Write-Utf8Text {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string[]]$Lines
  )
  $directory = Split-Path -Parent $Path
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), $script:utf8NoBom)
}

function Repair-MojibakeText {
  param([string]$Text)
  if ([string]::IsNullOrEmpty($Text)) { return $Text }
  if ($Text -notmatch $script:mojibakePattern) { return $Text }

  try {
    $windows1252 = [System.Text.Encoding]::GetEncoding(1252)
    $candidate = [System.Text.Encoding]::UTF8.GetString($windows1252.GetBytes($Text))
    $before = ([regex]::Matches($Text, $script:mojibakePattern)).Count
    $after = ([regex]::Matches($candidate, $script:mojibakePattern)).Count
    if ($after -lt $before) { return $candidate }
  } catch {
    return $Text
  }
  return $Text
}

function Normalize-ContextText {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
  $normalized = Repair-MojibakeText $Text
  $oldFeatureRoot = 'lib' + '/features'
  $oldAiRoot = 'lib' + '/services/ai'
  $oldNotificationRoot = 'lib' + '/services/notifications'
  $oldContextExamples = '\.codex/' + 'prompt' + 's'
  $normalized = $normalized -replace $oldFeatureRoot, 'lib/app_versions/v1/features'
  $normalized = $normalized -replace $oldAiRoot, 'lib/app_versions/v1/services/ai'
  $normalized = $normalized -replace $oldNotificationRoot, 'lib/app_versions/v1/services/notifications'
  $normalized = $normalized -replace $oldContextExamples, '.codex/skills or .codex/workflows'
  return $normalized
}

function Get-FirstMatch {
  param([string[]]$Lines, [string]$Pattern)
  foreach ($line in $Lines) {
    if ($line -match $Pattern) {
      return $line.Trim()
    }
  }
  return ""
}

function Clean-Value {
  param([string]$Line, [string]$Prefix)
  if ([string]::IsNullOrWhiteSpace($Line)) { return "" }
  return ($Line -replace [regex]::Escape($Prefix), "").Trim()
}

function Value-AfterColon {
  param([string]$Line)
  if ([string]::IsNullOrWhiteSpace($Line)) { return "" }
  return ($Line -replace '^-\s*[^:]+:\s*', '').Trim()
}

function ConvertTo-AsciiSlug {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
  $text = (Repair-MojibakeText $Text).ToLowerInvariant()
  $text = $text -replace ([string][char]0x0111), 'd'
  $text = $text -replace ([string][char]0x0110), 'd'
  $normalized = $text.Normalize([Text.NormalizationForm]::FormD)
  $builder = New-Object System.Text.StringBuilder
  foreach ($char in $normalized.ToCharArray()) {
    $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
    if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
      [void]$builder.Append($char)
    }
  }
  $slug = $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
  $slug = $slug -replace '[^a-z0-9]+', '-'
  $slug = $slug.Trim('-')
  return $slug
}

$canonicalTasks = @(
  [pscustomobject]@{ Key = "coding"; Title = "Coding"; Workflow = ".codex/workflows/coding.md" },
  [pscustomobject]@{ Key = "bugfix"; Title = "Direct bugfix"; Workflow = ".codex/workflows/bugfix.md" },
  [pscustomobject]@{ Key = "fix-issues"; Title = "Fix documented issue"; Workflow = ".codex/workflows/fix-issues.md" },
  [pscustomobject]@{ Key = "test"; Title = "Test and verification"; Workflow = ".codex/workflows/test.md" },
  [pscustomobject]@{ Key = "find-issues"; Title = "Review and find issues"; Workflow = ".codex/workflows/find-issues.md" },
  [pscustomobject]@{ Key = "create-issues"; Title = "Create issue docs"; Workflow = ".codex/workflows/create-issues.md" },
  [pscustomobject]@{ Key = "create-todo"; Title = "Create todo docs"; Workflow = ".codex/workflows/create-todo.md" },
  [pscustomobject]@{ Key = "docs-dd"; Title = "Design docs"; Workflow = ".codex/workflows/docs-dd.md" },
  [pscustomobject]@{ Key = "docs-context"; Title = "Context and docs update"; Workflow = ".codex/workflows/docs-context.md" },
  [pscustomobject]@{ Key = "refactor-scaffold"; Title = "Scaffold refactor"; Workflow = ".codex/workflows/refactor-scaffold.md" },
  [pscustomobject]@{ Key = "supabase-schema"; Title = "Supabase schema and RLS"; Workflow = ".codex/workflows/supabase-schema.md" }
)

$taskByKey = @{}
foreach ($task in $canonicalTasks) { $taskByKey[$task.Key] = $task }

$legacyAliasMap = [ordered]@{
  "coding-refactor" = "refactor-scaffold"
  "coding-test-docs" = "coding"
  "docs" = "docs-context"
  "docs-coding" = "supabase-schema"
  "docs-context-update" = "docs-context"
  "feature" = "coding"
  "feature-dashboard-ui-data-write-path" = "coding"
  "fix" = "bugfix"
  "fix-flow-d-li-u" = "bugfix"
  "fix-flow-du-lieu" = "bugfix"
  "fix-ui-copy" = "bugfix"
  "review-audit-docs" = "find-issues"
  "sua-docs-thiet-ke-lai-tai-lieu" = "docs-dd"
  "unknown" = "docs-context"
}

function Get-CanonicalTaskKey {
  param(
    [string]$TaskType,
    [string]$Module,
    [string]$Title,
    [string]$Path,
    [string]$Request
  )
  $typeSlug = ConvertTo-AsciiSlug $TaskType
  if ($script:taskByKey.ContainsKey($typeSlug)) { return $typeSlug }
  if ($script:legacyAliasMap.Contains($typeSlug)) { return $script:legacyAliasMap[$typeSlug] }

  $combinedSlug = ConvertTo-AsciiSlug "$TaskType $Module $Title $Path $Request"
  if ($combinedSlug -match 'supabase|rls|schema|sql|database|membership|quota|familyplus|referral|commission') { return "supabase-schema" }
  if ($combinedSlug -match 'refactor|scaffold|cau-truc|version-boundary') { return "refactor-scaffold" }
  if ($combinedSlug -match 'fix-issues|todo-fix|fix-todo') { return "fix-issues" }
  if ($combinedSlug -match 'create-todo|tao-todo') { return "create-todo" }
  if ($combinedSlug -match 'create-issue|tao-issue') { return "create-issues" }
  if ($combinedSlug -match 'review|audit|bug-audit|find-issue|release-readiness') { return "find-issues" }
  if ($combinedSlug -match 'test|analyze|format|build|verify|kiem-thu|kiem-chung') { return "test" }
  if ($combinedSlug -match 'dd|bd|design-doc|thiet-ke|product-flow|document-map') { return "docs-dd" }
  if ($combinedSlug -match 'codex|context|docs|worklog|checklist|history|task-skill|map-tree') { return "docs-context" }
  if ($combinedSlug -match 'fix|bug|loi') { return "bugfix" }
  if ($combinedSlug -match 'coding|feature|implement|code|auth|dashboard|onboarding') { return "coding" }
  return "docs-context"
}

function Escape-MarkdownTableCell {
  param([string]$Text)
  if ($null -eq $Text) { return "" }
  return (($Text -replace '\|', '\|') -replace "`r?`n", " ").Trim()
}

function Escape-MarkdownInlineText {
  param([string]$Text)
  if ($null -eq $Text) { return "" }
  $escaped = $Text -replace '&', '&amp;'
  $escaped = $escaped -replace '\[', '&#91;'
  $escaped = $escaped -replace '\]', '&#93;'
  return $escaped
}

function Strip-MarkdownCodeSpans {
  param([string]$Text)
  if ($null -eq $Text) { return "" }
  return ($Text -replace '`([^`]+)`', '$1')
}

function Get-ProjectRelativePath {
  param([Parameter(Mandatory = $true)][string]$Path)
  $full = (Resolve-Path $Path).Path
  return $full.Substring($script:root.Length + 1).Replace("\", "/")
}

function Get-RelativeMarkdownPath {
  param(
    [Parameter(Mandatory = $true)][string]$FromFile,
    [Parameter(Mandatory = $true)][string]$ToFile
  )
  $fromDirectory = (Resolve-Path (Split-Path -Parent $FromFile)).Path
  $toPath = (Resolve-Path $ToFile).Path
  $fromUri = New-Object System.Uri(($fromDirectory.TrimEnd('\') + '\'))
  $toUri = New-Object System.Uri($toPath)
  $relative = [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString())
  return $relative -replace '\\', '/'
}

Get-ChildItem -LiteralPath $taskSkillRoot -File -Filter "*.md" | Remove-Item -Force

$files = Get-ChildItem -Recurse -File $worklogRoot -Filter "*.md" | Sort-Object FullName
$entries = @()
$riskLines = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
  $relative = Get-ProjectRelativePath $file.FullName
  $content = Read-Utf8Text $file.FullName
  $lines = $content -split "`r?`n"
  $title = Normalize-ContextText (Clean-Value (Get-FirstMatch $lines "^# Worklog") "# ")
  if ([string]::IsNullOrWhiteSpace($title)) {
    $title = [IO.Path]::GetFileNameWithoutExtension($file.Name)
  }
  $date = Normalize-ContextText (Value-AfterColon (Get-FirstMatch $lines "^-\s*(Ng.*y|Date):"))
  if ([string]::IsNullOrWhiteSpace($date)) {
    $date = ($relative -split "/")[2]
  }
  $type = Strip-MarkdownCodeSpans (Normalize-ContextText (Value-AfterColon (Get-FirstMatch $lines "^-\s*(Lo.*task|Task type):")))
  if ([string]::IsNullOrWhiteSpace($type)) { $type = "unknown" }
  $module = Strip-MarkdownCodeSpans (Normalize-ContextText (Value-AfterColon (Get-FirstMatch $lines "^-\s*(Module ch.*|Main module):")))
  if ([string]::IsNullOrWhiteSpace($module)) { $module = "unknown" }
  $request = Strip-MarkdownCodeSpans (Normalize-ContextText (Value-AfterColon (Get-FirstMatch $lines "^-\s*(Y.*u c.*u.*|Original request):")))
  $taskKey = Get-CanonicalTaskKey -TaskType $type -Module $module -Title $title -Path $relative -Request $request

  $entries += [pscustomobject]@{
    Date = $date
    Type = $type
    TaskKey = $taskKey
    Module = $module
    Title = $title
    Path = $relative
    FullPath = $file.FullName
    Request = $request
  }

  foreach ($line in $lines) {
    $trimmed = Normalize-ContextText $line.Trim()
    $lineSlug = ConvertTo-AsciiSlug $trimmed
    if ($lineSlug -match "chua-fix|can-kiem-tra-tiep|rui-ro|todo|fail|partial|timeout|manual|q-0|blocked|needs-verification|skipped") {
      $riskLines.Add("${relative} :: $trimmed") | Out-Null
    }
  }
}

$indexFile = Join-Path $historyRoot "WORKLOG_INDEX.md"
$index = New-Object System.Collections.Generic.List[string]
$index.Add("# Worklog Index") | Out-Null
$index.Add("") | Out-Null
$index.Add('Generated from all `docs/worklog/**/*.md` files.') | Out-Null
$index.Add("") | Out-Null
$index.Add("- Total worklogs: $($entries.Count)") | Out-Null
$index.Add('- Refresh command: `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`') | Out-Null
$index.Add("") | Out-Null
$index.Add("## Entries") | Out-Null
$index.Add("") | Out-Null
$index.Add("| Date | Type | Canonical task | Module | Worklog |") | Out-Null
$index.Add("| --- | --- | --- | --- | --- |") | Out-Null
foreach ($entry in $entries) {
  $link = Get-RelativeMarkdownPath -FromFile $indexFile -ToFile $entry.FullPath
  $index.Add("| $(Escape-MarkdownTableCell $entry.Date) | $(Escape-MarkdownTableCell $entry.Type) | $($entry.TaskKey) | $(Escape-MarkdownTableCell $entry.Module) | [$($entry.Title)]($link) |") | Out-Null
}
Write-Utf8Text -Path $indexFile -Lines $index

$types = $entries | Group-Object TaskKey | Sort-Object Count -Descending
$modules = $entries | Group-Object Module | Sort-Object Count -Descending | Select-Object -First 12

$skills = New-Object System.Collections.Generic.List[string]
$skills.Add("# Learned Skills") | Out-Null
$skills.Add("") | Out-Null
$skills.Add('Generated from the full worklog corpus. Read this after `.codex/AGENTS.md`.') | Out-Null
$skills.Add("") | Out-Null
$skills.Add("## Canonical Work Types Seen") | Out-Null
$skills.Add("") | Out-Null
foreach ($group in $types) {
  $title = $taskByKey[$group.Name].Title
  $skills.Add("- $($group.Name) - ${title}: $($group.Count) worklog(s)") | Out-Null
}
$skills.Add("") | Out-Null
$skills.Add("## Frequent Modules") | Out-Null
$skills.Add("") | Out-Null
foreach ($group in $modules) {
  $skills.Add("- $($group.Name): $($group.Count)") | Out-Null
}
$skills.Add("") | Out-Null
$skills.Add("## Reusable Project Skills") | Out-Null
$skills.Add("") | Out-Null
$skills.Add('- Route every task through one workflow in `.codex/workflows/`, one generated task-skill in `.codex/task-skills/`, and one primary domain in `.codex/domains/`.') | Out-Null
$skills.Add("- For auth/access work, preserve v1 guest/basic, v2 authenticated free, v3 planned paid, and sale/referral as an independent axis.") | Out-Null
$skills.Add("- For AI work, validate/normalize output, avoid real Gemini calls in tests, keep fallback behavior, and log only safe summaries.") | Out-Null
$skills.Add("- For dashboard work, read real data through providers/repositories/datasources; do not add production mock data.") | Out-Null
$skills.Add('- For DD work, trace BD -> BR/AC/UC -> DD and keep open product decisions as `Status: Draft`.') | Out-Null
$skills.Add("- For issue/todo work, keep find issue, create issue, create todo, fix issue, and test as separate modes.") | Out-Null
$skills.Add("- For Supabase work, treat SQL files as drafts until sandbox/staging verification is recorded.") | Out-Null
$skills.Add("") | Out-Null
$skills.Add("## Command And Test Patterns") | Out-Null
$skills.Add("") | Out-Null
$skills.Add("- Prefer targeted tests before full quick check.") | Out-Null
$skills.Add('- Docs-only tasks use `rg` checks and `git diff --check`; skip Flutter analyze/test unless runtime code changes.') | Out-Null
$skills.Add('- Native commands in `.codex/tool/*.ps1` must run through `Invoke-NativeCommand` so non-zero exit codes fail the script.') | Out-Null
$skills.Add('- If Flutter/Dart tools time out, record the blocker and check stale `dart`/`flutter` processes instead of inventing results.') | Out-Null
$skills.Add("") | Out-Null
$skills.Add("## Post-Session Self Optimization") | Out-Null
$skills.Add("") | Out-Null
$skills.Add("- End every substantial session with a worklog self-review: output quality, task completion, verification strength, token efficiency, and next-session optimization.") | Out-Null
$skills.Add('- After writing the worklog, run the history refresh script so `.codex/history/` and `.codex/task-skills/` learn from the new session.') | Out-Null
$skills.Add('- Before starting a task, read the matching canonical `.codex/task-skills/<task-key>.md` after selecting the workflow.') | Out-Null
Write-Utf8Text -Path (Join-Path $historyRoot "LEARNED_SKILLS.md") -Lines $skills

$updated = (Get-Date).ToString("yyyy-MM-dd")
$risks = New-Object System.Collections.Generic.List[string]
$risks.Add("# Open Risks") | Out-Null
$risks.Add("") | Out-Null
$risks.Add("Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in `RISK_HISTORY.md`.") | Out-Null
$risks.Add("") | Out-Null
$risks.Add("## NB-RISK-001 Supabase sandbox/staging verification pending") | Out-Null
$risks.Add("") | Out-Null
$risks.Add("- Severity: P1") | Out-Null
$risks.Add("- Status: Needs Verification") | Out-Null
$risks.Add("- Updated: $updated") | Out-Null
$risks.Add("- Evidence: `docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md`; `docs/supabase/08-acceptance-checks.md`.") | Out-Null
$risks.Add("- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is verified outside docs.") | Out-Null
$risks.Add("- Proposed handling: Run Supabase local or sandbox verification, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.") | Out-Null
$risks.Add("- Owner/scope: Backend/Supabase implementation.") | Out-Null
Write-Utf8Text -Path (Join-Path $historyRoot "OPEN_RISKS.md") -Lines $risks

$riskHistory = New-Object System.Collections.Generic.List[string]
$riskHistory.Add("# Risk History") | Out-Null
$riskHistory.Add("") | Out-Null
$riskHistory.Add("Raw risk/failure/skip history extracted from worklogs. This file is not part of the default context pack unless exact history is needed.") | Out-Null
$riskHistory.Add("") | Out-Null
$riskHistory.Add("## Extracted Lines") | Out-Null
$riskHistory.Add("") | Out-Null
foreach ($line in $riskLines) {
  $riskHistory.Add("- $(Escape-MarkdownInlineText $line)") | Out-Null
}
Write-Utf8Text -Path (Join-Path $historyRoot "RISK_HISTORY.md") -Lines $riskHistory

$quality = @(
  "# Session Quality Review",
  "",
  "Use this checklist at the end of every substantial session before final response.",
  "",
  "## Required Self-Review Questions",
  "",
  "- Output quality: is the delivered artifact correct, coherent, scoped, and maintainable?",
  "- Task completion: which requested items are complete, partial, skipped, or unverified?",
  "- Verification strength: which commands or evidence prove completion, and what remains weak?",
  "- Token efficiency: what context was unnecessary, what could be indexed, and which workflow/domain/task-skill should be read next time?",
  '- Future optimization: should `.codex`, a workflow, a domain, or a task-skill be updated from this session?',
  "",
  "## Worklog Section",
  "",
  "Add this section to every new worklog:",
  "",
  '```md',
  "## Tu danh gia va toi uu phien sau",
  "",
  "- Chat luong dau ra: tot/can cai thien - ly do",
  "- Muc do hoan thanh task: ...",
  "- Bang chung kiem chung: ...",
  "- Diem ton token/chua toi uu: ...",
  "- Cach toi uu cho phien sau: ...",
  '- Task-skill can doc lan sau: `.codex/task-skills/<task-key>.md`',
  '```'
)
Write-Utf8Text -Path (Join-Path $historyRoot "SESSION_QUALITY_REVIEW.md") -Lines $quality

$taskReadmeFile = Join-Path $taskSkillRoot "README.md"
$taskReadme = New-Object System.Collections.Generic.List[string]
$taskReadme.Add("# Task Skills") | Out-Null
$taskReadme.Add("") | Out-Null
$taskReadme.Add("Generated from canonical task keys. Read the file matching the selected workflow/task before opening raw worklogs.") | Out-Null
$taskReadme.Add("") | Out-Null
$taskReadme.Add("| Task key | Title | Workflow | Worklogs | File |") | Out-Null
$taskReadme.Add("| --- | --- | --- | ---: | --- |") | Out-Null

foreach ($task in $canonicalTasks) {
  $taskKey = $task.Key
  $taskFile = Join-Path $taskSkillRoot "$taskKey.md"
  $taskEntries = @($entries | Where-Object { $_.TaskKey -eq $taskKey } | Sort-Object Date, Path)
  $taskTypes = $taskEntries | Group-Object Type | Sort-Object Count -Descending
  $taskModules = $taskEntries | Group-Object Module | Sort-Object Count -Descending | Select-Object -First 8

  $taskDoc = New-Object System.Collections.Generic.List[string]
  $taskDoc.Add("# Task Skill - $($task.Title)") | Out-Null
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("- Canonical key: $taskKey") | Out-Null
  $taskDoc.Add("- Workflow: $($task.Workflow)") | Out-Null
  $taskDoc.Add("- Generated from $($taskEntries.Count) worklog(s).") | Out-Null
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("## When To Read") | Out-Null
  $taskDoc.Add("") | Out-Null
  if ($taskEntries.Count -eq 0) {
    $taskDoc.Add("- Read this when the current request maps to $taskKey; no historical worklog has used this canonical key yet.") | Out-Null
  } else {
    foreach ($typeGroup in $taskTypes) {
      $taskDoc.Add("- Historical task type: $($typeGroup.Name) ($($typeGroup.Count))") | Out-Null
    }
  }
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("## Common Modules") | Out-Null
  $taskDoc.Add("") | Out-Null
  if ($taskModules.Count -eq 0) {
    $taskDoc.Add("- No historical module data yet.") | Out-Null
  } else {
    foreach ($moduleGroup in $taskModules) {
      $taskDoc.Add("- $($moduleGroup.Name): $($moduleGroup.Count)") | Out-Null
    }
  }
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("## Work Pattern") | Out-Null
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("- Start from the selected workflow, then this task skill, then one domain file.") | Out-Null
  if ($taskKey -eq "coding") {
    $taskDoc.Add("- Read `docs/checklist/checklist_complete_DD.md` first to identify DD module progress, blockers, and next step; then read `docs/checklist/checklist_task_coding.md` for prior-session coding notes.") | Out-Null
    $taskDoc.Add("- Before coding from a DD module, state the module, current progress percentages, blockers, and exact next task from the checklist.") | Out-Null
    $taskDoc.Add("- After coding, update `docs/checklist/checklist_complete_DD.md` and record upcoming work in `docs/checklist/checklist_task_coding.md`.") | Out-Null
  }
  $taskDoc.Add('- Prefer targeted `rg` and focused tests over broad reads/checks.') | Out-Null
  $taskDoc.Add("- Record exact evidence in the worklog and add the self-review section.") | Out-Null
  $taskDoc.Add("- Ask before expanding scope when BD/DD, issue/todo, or product decisions are missing.") | Out-Null
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("## Token Optimization") | Out-Null
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("- Ask: how can this task use fewer tokens while producing equal or better work?") | Out-Null
  $taskDoc.Add("- Read index/summary files before raw historical files.") | Out-Null
  $taskDoc.Add("- Stop reading when root cause, target files, and validation path are clear.") | Out-Null
  $taskDoc.Add("- Update this generated skill through the history refresh script, not by hand.") | Out-Null
  $taskDoc.Add("") | Out-Null
  $taskDoc.Add("## Source Worklogs") | Out-Null
  $taskDoc.Add("") | Out-Null
  if ($taskEntries.Count -eq 0) {
    $taskDoc.Add("- None yet.") | Out-Null
  } else {
    foreach ($entry in ($taskEntries | Select-Object -First 12)) {
      $link = Get-RelativeMarkdownPath -FromFile $taskFile -ToFile $entry.FullPath
      $taskDoc.Add("- [$($entry.Title)]($link) - $($entry.Module)") | Out-Null
    }
  }
  Write-Utf8Text -Path $taskFile -Lines $taskDoc
  $taskReadme.Add("| $taskKey | $($task.Title) | $($task.Workflow) | $($taskEntries.Count) | [$taskKey.md]($taskKey.md) |") | Out-Null
}

$taskReadme.Add("") | Out-Null
$taskReadme.Add("Legacy task keys are mapped in [LEGACY_TASK_KEY_MAP.md](LEGACY_TASK_KEY_MAP.md). Do not create new task-skill files outside the canonical key set.") | Out-Null
Write-Utf8Text -Path $taskReadmeFile -Lines $taskReadme

$legacy = New-Object System.Collections.Generic.List[string]
$legacy.Add("# Legacy Task Key Map") | Out-Null
$legacy.Add("") | Out-Null
$legacy.Add("Old generated task keys are mapped to canonical task keys so old worklogs remain understandable without keeping noisy generated skill files.") | Out-Null
$legacy.Add("") | Out-Null
$legacy.Add("| Legacy key | Canonical key |") | Out-Null
$legacy.Add("| --- | --- |") | Out-Null
foreach ($legacyKey in $legacyAliasMap.Keys) {
  $legacy.Add("| $legacyKey | $($legacyAliasMap[$legacyKey]) |") | Out-Null
}
Write-Utf8Text -Path (Join-Path $taskSkillRoot "LEGACY_TASK_KEY_MAP.md") -Lines $legacy

$refresh = @(
  "# History Refresh",
  "",
  'Run this after any session creates or updates `docs/worklog/**`.',
  "",
  '```powershell',
  'powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1',
  '```',
  "",
  "Outputs:",
  "",
  '- `WORKLOG_INDEX.md`: full worklog inventory with canonical task keys.',
  '- `LEARNED_SKILLS.md`: reusable project skills and command patterns.',
  '- `OPEN_RISKS.md`: compact active risk register only.',
  '- `RISK_HISTORY.md`: raw extracted historical risk/failure lines.',
  '- `SESSION_QUALITY_REVIEW.md`: self-review template for future sessions.',
  '- `.codex/task-skills/*.md`: generated canonical task-specific skills.',
  '- `HISTORY_REFRESH.md`: this instruction file.',
  "",
  'After refresh, run `.codex/tools/validate_codex_integrity.ps1` and include `.codex/history/*` plus `.codex/task-skills/*` in the docs/context diff.'
)
Write-Utf8Text -Path (Join-Path $historyRoot "HISTORY_REFRESH.md") -Lines $refresh

Write-Host "Updated .codex/history and canonical task-skills from $($entries.Count) worklog files."
