# Stock restore runbook

How to get back to official rabbitOS. Keep this path verified **before** you do anything
destructive.

> Warning: flashing is destructive and developer mode/unlock permanently voids the
> warranty. Rabbit support does not assist with unlocking/flashing/returning to stock.
> You are doing this on your own device at your own risk.

## A. Restore via official Rabbit Flash Tool (preferred)

1. Install the MediaTek USB driver (DRIVER-INSTALL-GUIDE-WINDOWS.md).
2. Download the official stock firmware for your installed version into
   `firmware/official/` and extract it with 7-Zip.
3. Verify the firmware download against the publisher's checksums, then record your own
   with `scripts/verify-hashes.ps1`.
4. Open the official Rabbit R1 Flash Tool, point it at the extracted firmware folder.
5. Follow the tool to enter fastboot/preloader and flash the stock ROM.
6. Reboot and confirm the device returns to stock rabbitOS.

## B. Restore individual partitions from your read-only dump (advanced)

Only if you intentionally changed a specific partition and want to revert it, using the
images you dumped in MTK-DUMP-RUNBOOK.md.

```powershell
.\.venv\Scripts\Activate.ps1
# Verify the image hash matches your manifest BEFORE writing
.\scripts\verify-hashes.ps1 -Verify -OutFile firmware\hashes\dump-manifest.sha256 -Path firmware\dumps

# Example: restore boot only (writes to device — destructive for that partition)
python -m mtkclient.mtk w boot firmware\dumps\boot.img
```

Caveats:

- `userdata` restore is unreliable due to file-based encryption; expect to set the
  device up fresh after a full restore.
- Never write `preloader`/`protect`/`nvram` unless you are certain — a bad write here
  can hard-brick or break radio/IMEI.

## C. If the device won't boot

1. Don't panic; a read-only state is usually recoverable via the Flash Tool.
2. Re-enter preloader/BROM and use the official Flash Tool with the full stock package.
3. As a last resort, use your verified offline dump to restore the boot chain partitions.

## Post-restore checklist

- [ ] Device boots to stock rabbitOS.
- [ ] Version matches expected stock build.
- [ ] Wi-Fi / SIM / sensors function.
- [ ] Re-record device info if anything changed.
