# Windows driver & tool install guide

Target: Windows 11 / Windows Server with a Rabbit R1 (MediaTek MT6765 / Helio P35).

The R1 has no volume buttons, so fastboot entry generally requires preloader serial
tooling (mtkclient / mtkbootcmd). Get USB enumeration working first.

## 1. Android SDK Platform-Tools (adb + fastboot)

- Download Google's "SDK Platform-Tools for Windows".
- Extract to e.g. `C:\platform-tools` and add it to PATH.
- Verify:

```powershell
adb version
fastboot --version
```

## 2. Google USB Driver / Android USB drivers

- Install Google's USB Driver (for ADB/fastboot recognition).
- After install, `adb devices` should list the device once it is in an ADB-capable mode.

## 3. MediaTek Preloader / VCOM USB driver

- The R1 briefly enumerates as an `MT65xx Preloader` / VCOM device during boot.
- Install the MediaTek USB VCOM (preloader) driver so this port is recognized.
- Use `scripts/list-usb-devices.ps1` while plugging the device to confirm it appears.

## 4. UsbDk (required by mtkclient on Windows)

- Install UsbDk (USB Development Kit). mtkclient uses it to talk to the preloader/BROM.

## 5. Python + mtkclient

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install mtkclient
```

mtkclient is a MediaTek read/write/repair utility. In this kit we use it for
**read-only** operations first (see MTK-DUMP-RUNBOOK.md).

## 6. Supporting tools

| Tool | Purpose |
|------|---------|
| 7-Zip | extract firmware / images |
| Git | clone reference repos |
| HxD or ImHex | inspect partition images (hex) |
| JADX-GUI / APKTool | APK static analysis (your own apps / study) |
| Ghidra | native binary RE (study) |
| scrcpy | screen mirror once ADB works |

## Linux note

MTK/BROM USB timing is often more reliable on bare-metal Linux than Windows/WSL. If you
hit preloader timing issues on Windows, a Linux box with `adb fastboot usbutils` and
mtkclient may work better. WSL is unreliable for preloader/BROM timing.

## Verifying enumeration

```powershell
.\scripts\list-usb-devices.ps1
```

Plug the R1 in and watch for the MediaTek preloader/VCOM device or an ADB device to
appear. Once it does, proceed to the dump runbook.
