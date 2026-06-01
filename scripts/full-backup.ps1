<#
.SYNOPSIS
  One-command FULL read-only backup of a Rabbit R1 (MediaTek MT6765).

.DESCRIPTION
  Run this on the PC the R1 is physically plugged into. It will:
    1. Create a Python venv and install mtkclient (+ deps).
    2. Print the partition table (GPT).
    3. Read-only dump EVERY partition (nothing excluded) into firmware\dumps.
    4. SHA-256 hash the whole dump into firmware\hashes.

  This script only READS from the device. It never writes/erases/unlocks anything.

  Device-private partitions (nvram, nvdata, persist, protect, userdata) ARE included
  because you asked for a complete backup. Keep these files private — never upload them.

.PARAMETER OutDir
  Where to write images. Default: ..\firmware\dumps

.PARAMETER ExcludeUserdata
  Skip the (large, encrypted) userdata partition. Off by default (full backup).

.PARAMETER SkipInstall
  Skip venv/mtkclient setup (use if already installed).

.EXAMPLE
  .\full-backup.ps1
#>
[CmdletBinding()]
param(
  [string]$OutDir = "",
  [switch]$ExcludeUserdata,
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
$root = (Resolve-Path (Join-Path $ScriptDir "..")).Path
if (-not $OutDir) { $OutDir = Join-Path $root "firmware\dumps" }
$venv = Join-Path $root ".venv"
$hashOut = Join-Path $root "firmware\hashes\dump-manifest.sha256"

function Find-Python {
  foreach ($c in @("py -3.12","py -3.11","py -3","python")) {
    $parts = $c.Split(" ")
    if (Get-Command $parts[0] -ErrorAction SilentlyContinue) { return $c }
  }
  throw "Python 3.11/3.12 not found. Install it first (see docs/DRIVER-INSTALL-GUIDE-WINDOWS.md)."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $hashOut) | Out-Null

# --- 1. Setup mtkclient ---
if (-not $SkipInstall) {
  $py = Find-Python
  Write-Host "[setup] using interpreter: $py" -ForegroundColor Cyan
  if (-not (Test-Path $venv)) {
    Write-Host "[setup] creating venv at $venv" -ForegroundColor Cyan
    Invoke-Expression "$py -m venv `"$venv`""
  }
  $vpy = Join-Path $venv "Scripts\python.exe"
  & $vpy -m pip install --upgrade pip
  Write-Host "[setup] installing mtkclient..." -ForegroundColor Cyan
  & $vpy -m pip install --upgrade mtkclient
} else {
  $vpy = Join-Path $venv "Scripts\python.exe"
  if (-not (Test-Path $vpy)) { throw "venv not found; run without -SkipInstall first." }
}

function Mtk {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$args)
  & $vpy -m mtkclient.mtk @args
}

Write-Host ""
Write-Host "================ Rabbit R1 FULL read-only backup ================" -ForegroundColor Green
Write-Host "Output: $OutDir"
Write-Host "When prompted, power the R1 OFF and plug it in so mtkclient catches BROM." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# --- 2. Partition table ---
Write-Host "[dump] reading partition table (printgpt)..." -ForegroundColor Cyan
try {
  Mtk printgpt | Tee-Object -FilePath (Join-Path $OutDir "printgpt.txt")
} catch {
  Write-Host "[warn] printgpt failed or device not caught yet: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- 3. Full dump of ALL partitions ---
# `rl` reads every partition listed in the GPT into the output folder.
Write-Host "[dump] reading ALL partitions (this can take a while)..." -ForegroundColor Cyan
if ($ExcludeUserdata) {
  Mtk rl $OutDir --skip userdata
} else {
  Mtk rl $OutDir
}

# Some preloader regions are read separately on certain MT6765 layouts.
Write-Host "[dump] ensuring preloader region is captured..." -ForegroundColor Cyan
try {
  Mtk r preloader (Join-Path $OutDir "preloader.bin")
} catch {
  Write-Host "[info] preloader already included via rl or not separately readable." -ForegroundColor DarkGray
}

# --- 4. Hash everything ---
Write-Host "[hash] writing SHA-256 manifest..." -ForegroundColor Cyan
& (Join-Path $ScriptDir "verify-hashes.ps1") -Path $OutDir -OutFile $hashOut

Write-Host ""
Write-Host "DONE. Full backup in: $OutDir" -ForegroundColor Green
Write-Host "Manifest: $hashOut" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT:" -ForegroundColor Cyan
Write-Host "  1. Copy firmware\dumps + firmware\hashes to OFFLINE storage."
Write-Host "  2. Re-verify after copying:  .\scripts\verify-hashes.ps1 -Verify"
Write-Host "  3. Keep nvram/nvdata/persist/protect/userdata images PRIVATE."
