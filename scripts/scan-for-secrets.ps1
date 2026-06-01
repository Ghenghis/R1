<#
.SYNOPSIS
  Scan the working tree for accidentally-committed secrets before commit/zip.

.DESCRIPTION
  Looks for common API-key patterns and non-empty *_API_KEY assignments in tracked
  files. Ignores private/, node_modules/, firmware dumps, and *.example templates.
  Exits non-zero if anything suspicious is found.

.EXAMPLE
  .\scan-for-secrets.ps1
#>
[CmdletBinding()]
param(
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $Root) { $Root = (Resolve-Path (Join-Path $ScriptDir "..")).Path }

$excludeDirs = @("\private\", "\node_modules\", "\.git\", "\firmware\dumps\", "\firmware\official\", "\.venv\")
$excludeFiles = @(".example")

# Patterns: provider-ish keys + any non-empty *_API_KEY=...
$patterns = @(
  'sk-[A-Za-z0-9]{16,}',                 # OpenAI-style
  'sk-or-[A-Za-z0-9-]{16,}',             # router-style
  '[A-Za-z0-9_\-]*_API_KEY[ \t]*=[ \t]*[''"]?[A-Za-z0-9\-\.]{16,}', # filled key var (single line)
  'AKIA[0-9A-Z]{16}',                    # AWS access key id
  'eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.'             # JWT-ish
)

$findings = New-Object System.Collections.Generic.List[string]

Get-ChildItem -Recurse -File -Path $Root | ForEach-Object {
  $full = $_.FullName
  foreach ($d in $excludeDirs) { if ($full -like "*$d*") { return } }
  foreach ($e in $excludeFiles) { if ($_.Name -like "*$e") { return } }
  if ($_.Length -gt 2MB) { return }

  $content = Get-Content -Raw -ErrorAction SilentlyContinue $full
  if (-not $content) { return }

  foreach ($p in $patterns) {
    $m = [regex]::Matches($content, $p)
    foreach ($hit in $m) {
      $val = $hit.Value
      # Allow obvious placeholders/empties.
      if ($val -match '=\s*[''"]?\s*$') { continue }
      if ($val -match 'your_own_key|your_key|placeholder|example|<.*>') { continue }
      $rel = $full.Substring($Root.Length).TrimStart('\','/')
      $findings.Add("$rel :: $($val.Substring(0,[Math]::Min(40,$val.Length)))...")
    }
  }
}

if ($findings.Count -gt 0) {
  Write-Host "POTENTIAL SECRETS FOUND:" -ForegroundColor Red
  $findings | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  Write-Host ""
  Write-Host "Remove/rotate these before committing or zipping." -ForegroundColor Yellow
  exit 1
}

Write-Host "No secrets detected in the working tree (private/ and dumps excluded)." -ForegroundColor Green
exit 0
