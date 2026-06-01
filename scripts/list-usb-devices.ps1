<#
.SYNOPSIS
  List USB/serial devices, highlighting MediaTek preloader/VCOM ports useful for the R1.

.DESCRIPTION
  Helps confirm the Rabbit R1 enumerates (MediaTek preloader/VCOM or an ADB device)
  before attempting a dump. Read-only; touches nothing on the device.

.EXAMPLE
  .\list-usb-devices.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Serial (COM) ports ===" -ForegroundColor Cyan
Get-CimInstance Win32_SerialPort |
  Select-Object DeviceID, Description, PNPDeviceID |
  Format-Table -AutoSize

Write-Host "=== PnP devices matching MediaTek / Preloader / VCOM / MT65 ===" -ForegroundColor Cyan
Get-PnpDevice |
  Where-Object {
    $_.FriendlyName -match "MediaTek|Preloader|VCOM|MT65|USB Serial"
  } |
  Select-Object Status, Class, FriendlyName, InstanceId |
  Format-Table -AutoSize

Write-Host "=== ADB devices (if platform-tools on PATH) ===" -ForegroundColor Cyan
if (Get-Command adb -ErrorAction SilentlyContinue) {
  adb devices
} else {
  Write-Host "adb not found on PATH (install Android SDK Platform-Tools)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Tip: the R1 shows up as an MTxx Preloader/VCOM device only briefly during boot." -ForegroundColor DarkGray
Write-Host "Re-run this while plugging the device in if you don't see it." -ForegroundColor DarkGray
