# Recovery-first checklist

Do these in order. Do not unlock, flash, wipe, or write any partition until every box
in Phases 0–4 is checked.

> Note on versions: this checklist is hardware-/process-oriented and does not assume a
> specific rabbitOS build. Always pair it with the *current* official firmware and
> Flash Tool for your device's installed version. Record your installed version in
> `docs/rabbitos2-device-info.md` (create it as you go).

## Phase 0 — Record device state (no writes)

- [ ] Photograph / screenshot the device info screen.
- [ ] Note installed rabbitOS version exactly.
- [ ] Note IMEI, serial, SIM status, Wi-Fi state, account status. **Keep this private.**
- [ ] Save these under `00-device-info` notes (do not commit IMEI/serial publicly).

## Phase 1 — Gather official recovery sources (download only)

- [ ] Official stock firmware (`rabbit-hmi-oss/firmware`).
- [ ] Official Rabbit R1 Flash Tool.
- [ ] Official kernel source (`rabbit-hmi-oss/android_kernel_rabbit_mt6765`) — optional, for study.
- [ ] Official Creations SDK (`rabbit-hmi-oss/creations-sdk`).
- [ ] Run `scripts/clone-repos.ps1` to pull the GREEN/YELLOW reference repos into `firmware/` / a tools folder.

See [DRIVER-INSTALL-GUIDE-WINDOWS.md](DRIVER-INSTALL-GUIDE-WINDOWS.md) for drivers/tools.

## Phase 2 — Drivers and tools

- [ ] Android SDK Platform-Tools (adb, fastboot) on PATH.
- [ ] MediaTek Preloader/VCOM USB driver installed.
- [ ] UsbDk installed (for mtkclient on Windows).
- [ ] Python 3.11/3.12 + `mtkclient` installed in a venv.
- [ ] `scripts/list-usb-devices.ps1` shows the R1 when plugged in.

## Phase 3 — Read-only dump

Follow [MTK-DUMP-RUNBOOK.md](MTK-DUMP-RUNBOOK.md).

- [ ] Dump preloader, GPT/partition table.
- [ ] Dump boot, vendor_boot, vbmeta, dtbo.
- [ ] Dump super / system / vendor / product / odm (if present).
- [ ] Dump persist / nvdata / nvram / protect (if readable) — **keep private**.
- [ ] Only consider userdata if you understand the encryption limits.

## Phase 4 — Verify and archive

- [ ] `scripts/verify-hashes.ps1` produces a SHA-256 manifest for every image.
- [ ] Copy the dump + manifest to offline storage.
- [ ] Confirm you can locate the official stock restore for your version
      ([STOCK-RESTORE-RUNBOOK.md](STOCK-RESTORE-RUNBOOK.md)).

## Phase 5 — Only now: optional unlock / custom ROM

Everything past here is destructive. Re-read [RISK-REGISTER.md](RISK-REGISTER.md).
You have a verified dump and a known restore path — proceed only if you accept the
warranty void and wipe.
