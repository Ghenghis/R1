<#
.SYNOPSIS
  Clone the GREEN/YELLOW reference repos for Rabbit R1 recovery and study.

.DESCRIPTION
  Clones official Rabbit sources and well-known community tooling into a tools folder.
  RED / research-only resources (cloud API impersonation, account-key material) are
  intentionally NOT cloned by this script.

.PARAMETER Dest
  Destination folder for clones. Default: ..\firmware\tools

.EXAMPLE
  .\clone-repos.ps1
#>
[CmdletBinding()]
param(
  [string]$Dest = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $Dest) { $Dest = Join-Path $ScriptDir "..\firmware\tools" }

# GREEN: official Rabbit + standard tooling.
$green = @(
  "https://github.com/rabbit-hmi-oss/firmware.git",
  "https://github.com/rabbit-hmi-oss/creations-sdk.git",
  "https://github.com/rabbit-hmi-oss/android_kernel_rabbit_mt6765.git",
  "https://github.com/bkerler/mtkclient.git"
)

# YELLOW: community study/reference. Verify before running write/unlock steps.
$yellow = @(
  "https://github.com/DavidBuchanan314/rabbit_r1_boot_notes.git",
  "https://github.com/sayhiben/awesome-rabbit-r1.git",
  "https://github.com/TurboTheTurtle/rabbit-r1-firmware.git"
)

if (-not (Test-Path $Dest)) {
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
}
$Dest = (Resolve-Path $Dest).Path

function Clone-One($url, $tag) {
  $name = ($url -replace '\.git$','') -split '/' | Select-Object -Last 1
  $target = Join-Path $Dest $name
  if (Test-Path $target) {
    Write-Host "[$tag] skip (exists): $name" -ForegroundColor DarkGray
    return
  }
  Write-Host "[$tag] clone: $url" -ForegroundColor Cyan
  git clone --depth 1 $url $target
}

Write-Host "Cloning GREEN (official / standard) repos..." -ForegroundColor Green
foreach ($u in $green) { Clone-One $u "GREEN" }

Write-Host "Cloning YELLOW (community, verify before running) repos..." -ForegroundColor Yellow
foreach ($u in $yellow) { Clone-One $u "YELLOW" }

Write-Host ""
Write-Host "Done. Reviewed in docs/RISK-REGISTER.md." -ForegroundColor Green
Write-Host "NOTE: RED / research-only cloud-API material is intentionally not cloned." -ForegroundColor Magenta
