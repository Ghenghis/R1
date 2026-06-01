<#
.SYNOPSIS
  Safely health-check YOUR OWN MiniMax/DeepSeek/SiliconFlow keys.

.DESCRIPTION
  Reads keys ONLY from environment variables you loaded from private\.env.local
  (use load-env-local.ps1 first). It never reads keys from repos, gists, firmware,
  dumps, logs, or Rabbit cloud, and it never touches Rabbit services.

  Modes:
    MaskOnly  - just report which keys are present (masked). No network calls.
    Models    - GET each provider's /models endpoint (cheap reachability/auth check).
    ChatSmoke - tiny 1-token chat completion (spends a small amount of credit).
                Requires -Confirm to run.

.PARAMETER Mode
  MaskOnly (default) | Models | ChatSmoke

.PARAMETER Confirm
  Required for ChatSmoke (acknowledges it spends provider credit).

.EXAMPLE
  . .\scripts\load-env-local.ps1
  .\scripts\test-provider-keys-safe.ps1 -Mode MaskOnly
  .\scripts\test-provider-keys-safe.ps1 -Mode Models
  .\scripts\test-provider-keys-safe.ps1 -Mode ChatSmoke -Confirm
#>
[CmdletBinding()]
param(
  [ValidateSet("MaskOnly","Models","ChatSmoke")]
  [string]$Mode = "MaskOnly",
  [switch]$Confirm
)

$ErrorActionPreference = "Stop"

$providers = @(
  @{ id="minimax";     keyVar="MINIMAX_API_KEY";     baseVar="MINIMAX_BASE_URL";     baseDefault="https://api.minimax.io/v1";    model="MiniMax-Text-01" },
  @{ id="deepseek";    keyVar="DEEPSEEK_API_KEY";    baseVar="DEEPSEEK_BASE_URL";    baseDefault="https://api.deepseek.com";     model="deepseek-chat" },
  @{ id="siliconflow"; keyVar="SILICONFLOW_API_KEY"; baseVar="SILICONFLOW_BASE_URL"; baseDefault="https://api.siliconflow.cn/v1"; model="deepseek-ai/DeepSeek-V3" }
)

function Mask([string]$v) {
  if (-not $v) { return "(missing)" }
  if ($v.Length -le 8) { return "****" }
  return $v.Substring(0,4) + "..." + $v.Substring($v.Length-4)
}

function Get-Base($p) {
  $b = [Environment]::GetEnvironmentVariable($p.baseVar)
  if (-not $b) { $b = $p.baseDefault }
  return $b.TrimEnd("/")
}

if ($Mode -eq "ChatSmoke" -and -not $Confirm) {
  Write-Host "ChatSmoke spends a small amount of provider credit. Re-run with -Confirm." -ForegroundColor Yellow
  exit 2
}

Write-Host "Provider key health check (mode: $Mode)" -ForegroundColor Cyan
Write-Host "Keys are read only from your environment (private\.env.local)." -ForegroundColor DarkGray
Write-Host ""

foreach ($p in $providers) {
  $key = [Environment]::GetEnvironmentVariable($p.keyVar)
  $base = Get-Base $p
  $tag = $p.id.PadRight(12)

  if (-not $key) {
    Write-Host "$tag SKIP  (no $($p.keyVar) set)" -ForegroundColor DarkGray
    continue
  }

  if ($Mode -eq "MaskOnly") {
    Write-Host "$tag PRESENT $(Mask $key)  base=$base" -ForegroundColor Green
    continue
  }

  $headers = @{ Authorization = "Bearer $key" }

  try {
    if ($Mode -eq "Models") {
      $resp = Invoke-RestMethod -Method Get -Uri "$base/models" -Headers $headers -TimeoutSec 30
      $n = 0
      if ($resp.data) { $n = $resp.data.Count }
      Write-Host "$tag GREEN  /models reachable ($n models)  $(Mask $key)" -ForegroundColor Green
    }
    elseif ($Mode -eq "ChatSmoke") {
      $body = @{
        model = $p.model
        messages = @(@{ role="user"; content="ping" })
        max_tokens = 1
      } | ConvertTo-Json -Depth 5
      $resp = Invoke-RestMethod -Method Post -Uri "$base/chat/completions" -Headers $headers -ContentType "application/json" -Body $body -TimeoutSec 60
      $model = $resp.model
      Write-Host "$tag GREEN  chat ok (model=$model)  $(Mask $key)" -ForegroundColor Green
    }
  }
  catch {
    $status = $null
    try { $status = $_.Exception.Response.StatusCode.value__ } catch {}
    $level = if ($status -and $status -ge 500) { "YELLOW" } else { "RED" }
    $color = if ($level -eq "YELLOW") { "Yellow" } else { "Red" }
    Write-Host "$tag $level  $($_.Exception.Message) (HTTP $status)" -ForegroundColor $color
  }
}

Write-Host ""
Write-Host "Reminder: this tool only ever tests your own keys. Never test found/leaked or Rabbit keys." -ForegroundColor DarkGray
