<#
Captures a snapshot of all usage meters relevant to the Fable-fee experiment (B21-B25):
- Local ~/.claude/usage_snapshot.json (five_hour, seven_day pools that gate this protocol)
- The three meters shown on the claude.ai usage settings page (session, all-models weekly,
  Fable weekly), which the orchestrator reads via Chrome MCP and passes in as parameters
  since that page is not scriptable from PowerShell alone.

Appends one JSON line to fable_fee_log.jsonl (repo root), same append-only spirit as
budget_log.jsonl: never edit past lines, append a correction line instead.

Usage:
  ./scripts/capture_meters.ps1 -Label baseline `
    -ChromeSessionPct 26 -ChromeAllModelsWeeklyPct 24 -ChromeFableWeeklyPct 23 `
    -Note "before B23 Fable-agent measured load"
#>
param(
    [Parameter(Mandatory=$true)][string]$Label,
    [Parameter(Mandatory=$true)][int]$ChromeSessionPct,
    [Parameter(Mandatory=$true)][int]$ChromeAllModelsWeeklyPct,
    [Parameter(Mandatory=$true)][int]$ChromeFableWeeklyPct,
    [string]$Note = ""
)

$snapshotPath = Join-Path $env:USERPROFILE ".claude\usage_snapshot.json"
if (-not (Test-Path $snapshotPath)) {
    throw "usage_snapshot.json not found at $snapshotPath"
}
$snapshot = Get-Content $snapshotPath -Raw | ConvertFrom-Json

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$logPath = Join-Path $repoRoot "fable_fee_log.jsonl"

$entry = [ordered]@{
    t      = "reading"
    ts     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    label  = $Label
    snapshot = [ordered]@{
        five_hour_pct        = $snapshot.rate_limits.five_hour.used_percentage
        five_hour_resets_at  = $snapshot.rate_limits.five_hour.resets_at
        seven_day_pct        = $snapshot.rate_limits.seven_day.used_percentage
        seven_day_resets_at  = $snapshot.rate_limits.seven_day.resets_at
    }
    chrome = [ordered]@{
        session_pct            = $ChromeSessionPct
        all_models_weekly_pct   = $ChromeAllModelsWeeklyPct
        fable_weekly_pct        = $ChromeFableWeeklyPct
    }
}
if ($Note) { $entry["note"] = $Note }

$json = $entry | ConvertTo-Json -Compress -Depth 5
Add-Content -Path $logPath -Value $json -Encoding utf8
Write-Output "Appended reading '$Label' to $logPath"
