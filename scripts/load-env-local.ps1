<#
.SYNOPSIS
  Load KEY=VALUE pairs from a local env file into the current PowerShell session.

.DESCRIPTION
  Dot-source this script to set environment variables for the key health check:
      . .\scripts\load-env-local.ps1 -Path .\private\.env.local

  Only loads from a file YOU control (default private\.env.local). Values are not echoed.

.PARAMETER Path
  Env file to load. Default: ..\private\.env.local
#>
[CmdletBinding()]
param(
  [string]$Path = ""
)

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $Path) { $Path = Join-Path $ScriptDir "..\private\.env.local" }

if (-not (Test-Path $Path)) {
  Write-Host "Env file not found: $Path" -ForegroundColor Red
  Write-Host "Copy templates\.env.local.example to private\.env.local and add YOUR keys." -ForegroundColor Yellow
  return
}

$count = 0
Get-Content $Path | ForEach-Object {
  $line = $_.Trim()
  if ($line -eq "" -or $line.StartsWith("#")) { return }
  $idx = $line.IndexOf("=")
  if ($idx -lt 1) { return }
  $name = $line.Substring(0, $idx).Trim()
  $value = $line.Substring($idx + 1).Trim().Trim('"').Trim("'")
  if ($value -eq "") { return }
  Set-Item -Path ("Env:{0}" -f $name) -Value $value
  $count++
}
Write-Host "Loaded $count variable(s) from $Path (values hidden)." -ForegroundColor Green
