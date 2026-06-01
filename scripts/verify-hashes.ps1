<#
.SYNOPSIS
  Create or verify a SHA-256 manifest for files in a folder.

.DESCRIPTION
  Default mode writes a manifest of SHA-256 hashes for every file under -Path.
  -Verify mode re-hashes and compares against an existing manifest.

.PARAMETER Path
  Folder to hash. Default: ..\firmware\dumps

.PARAMETER OutFile
  Manifest path. Default: ..\firmware\hashes\dump-manifest.sha256

.PARAMETER Verify
  Verify existing files against the manifest instead of writing it.

.EXAMPLE
  .\verify-hashes.ps1
  .\verify-hashes.ps1 -Verify
#>
[CmdletBinding()]
param(
  [string]$Path = "",
  [string]$OutFile = "",
  [switch]$Verify
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $Path)    { $Path = Join-Path $ScriptDir "..\firmware\dumps" }
if (-not $OutFile) { $OutFile = Join-Path $ScriptDir "..\firmware\hashes\dump-manifest.sha256" }

if (-not (Test-Path $Path)) {
  throw "Path not found: $Path"
}
$Path = (Resolve-Path $Path).Path

if ($Verify) {
  if (-not (Test-Path $OutFile)) { throw "Manifest not found: $OutFile" }
  $fail = 0; $ok = 0
  Get-Content $OutFile | ForEach-Object {
    if ($_ -notmatch '^\s*([0-9a-fA-F]{64})\s+\*?(.+)$') { return }
    $expected = $Matches[1].ToLower()
    $rel = $Matches[2].Trim()
    $full = Join-Path $Path $rel
    if (-not (Test-Path $full)) {
      Write-Host "MISSING  $rel" -ForegroundColor Red; $fail++; return
    }
    $actual = (Get-FileHash -Algorithm SHA256 -Path $full).Hash.ToLower()
    if ($actual -eq $expected) {
      Write-Host "OK       $rel" -ForegroundColor Green; $ok++
    } else {
      Write-Host "MISMATCH $rel" -ForegroundColor Red; $fail++
    }
  }
  Write-Host ""
  Write-Host "Verified: $ok OK, $fail problem(s)." -ForegroundColor ($(if ($fail) {"Red"} else {"Green"}))
  if ($fail) { exit 1 }
  exit 0
}

# Write mode
$outDir = Split-Path -Parent $OutFile
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$lines = New-Object System.Collections.Generic.List[string]
$files = Get-ChildItem -Recurse -File -Path $Path | Sort-Object FullName
if ($files.Count -eq 0) {
  Write-Host "No files to hash under $Path (run a dump first)." -ForegroundColor Yellow
}
foreach ($f in $files) {
  $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash.ToLower()
  $rel = $f.FullName.Substring($Path.Length).TrimStart('\','/')
  $lines.Add("$hash  $rel")
  Write-Host "$hash  $rel"
}
Set-Content -Path $OutFile -Value $lines -Encoding ASCII
Write-Host ""
Write-Host "Wrote manifest: $OutFile ($($files.Count) file(s))." -ForegroundColor Green
